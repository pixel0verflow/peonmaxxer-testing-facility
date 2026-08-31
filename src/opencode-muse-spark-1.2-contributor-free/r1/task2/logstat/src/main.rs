use std::env;
use std::fs::File;
use std::io::{BufRead, BufReader, Write};
use std::process;

const VALID_METHODS: &[&str] = &["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"];
const VALID_STATUS_CLASSES: &[&str] = &["2xx", "3xx", "4xx", "5xx"];

#[derive(Debug, Clone)]
struct Entry {
    method: String,
    path: String,
    status: u16,
    latency: u64,
    normalized: String,
}

mod parse {
    use super::{Entry, VALID_METHODS};

    pub fn parse_line(line: &str) -> Option<Entry> {
        // split on whitespace (normalizes single spaces) and require exactly 5 fields
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() != 5 {
            return None;
        }
        let ts = parts[0];
        let method = parts[1];
        let path = parts[2];
        let status_str = parts[3];
        let latency_str = parts[4];

        if !is_valid_timestamp(ts) {
            return None;
        }
        if !VALID_METHODS.contains(&method) {
            return None;
        }
        if !path.starts_with('/') {
            return None;
        }
        if !is_valid_status(status_str) {
            return None;
        }
        if !is_valid_latency(latency_str) {
            return None;
        }

        let status: u16 = status_str.parse().ok()?;
        let latency: u64 = latency_str.parse().ok()?;

        let normalized = parts.join(" ");

        Some(Entry {
            method: method.to_string(),
            path: path.to_string(),
            status,
            latency,
            normalized,
        })
    }

    fn is_valid_timestamp(s: &str) -> bool {
        s.len() == 20 && s.ends_with('Z') && s.contains('T')
    }

    fn is_valid_status(s: &str) -> bool {
        s.len() == 3 && s.chars().all(|c| c.is_ascii_digit())
    }

    fn is_valid_latency(s: &str) -> bool {
        !s.is_empty() && s.chars().all(|c| c.is_ascii_digit())
    }
}

mod agg {
    use std::collections::HashMap;

    #[derive(Debug, Default)]
    pub struct PathStats {
        pub requests: usize,
        pub errors: usize,
        pub latencies: Vec<u64>,
    }

    pub fn percentile(sorted: &[u64], p: usize) -> u64 {
        // nearest-rank: ceil(p/100 * N), 1-indexed
        let n = sorted.len();
        debug_assert!(n > 0);
        let rank = (p * n + 99) / 100; // ceil(p*n/100)
        let idx = rank - 1;
        sorted[idx]
    }

    pub fn aggregate(entries: &[super::Entry]) -> HashMap<String, PathStats> {
        let mut map: HashMap<String, PathStats> = HashMap::new();
        for e in entries {
            let st = map.entry(e.path.clone()).or_default();
            st.requests += 1;
            if e.status >= 500 {
                st.errors += 1;
            }
            st.latencies.push(e.latency);
        }
        for st in map.values_mut() {
            st.latencies.sort_unstable();
        }
        map
    }

    #[derive(Debug)]
    pub struct SummaryRow {
        pub path: String,
        pub requests: usize,
        pub errors: usize,
        pub p50: u64,
        pub p95: u64,
    }

    pub fn sorted_rows(map: &HashMap<String, PathStats>) -> Vec<SummaryRow> {
        let mut rows: Vec<SummaryRow> = map
            .iter()
            .map(|(path, st)| {
                let p50 = percentile(&st.latencies, 50);
                let p95 = percentile(&st.latencies, 95);
                SummaryRow {
                    path: path.clone(),
                    requests: st.requests,
                    errors: st.errors,
                    p50,
                    p95,
                }
            })
            .collect();
        rows.sort_by(|a, b| b.requests.cmp(&a.requests).then_with(|| a.path.cmp(&b.path)));
        rows
    }
}

mod output {
    use super::agg::SummaryRow;
    use std::io::Write;

    pub fn write_tsv<W: Write>(w: &mut W, rows: &[SummaryRow], skipped: usize) -> std::io::Result<()> {
        writeln!(w, "path\trequests\terrors\tp50_ms\tp95_ms")?;
        for r in rows {
            writeln!(
                w,
                "{}\t{}\t{}\t{}\t{}",
                r.path, r.requests, r.errors, r.p50, r.p95
            )?;
        }
        writeln!(w, "skipped\t{}", skipped)?;
        Ok(())
    }

    pub fn write_json<W: Write>(w: &mut W, rows: &[SummaryRow], skipped: usize) -> std::io::Result<()> {
        write!(w, "{{\"paths\":[")?;
        for (i, r) in rows.iter().enumerate() {
            if i > 0 {
                write!(w, ",")?;
            }
            write!(
                w,
                "{{\"path\":\"{}\",\"requests\":{},\"errors\":{},\"p50_ms\":{},\"p95_ms\":{}}}",
                json_escape(&r.path),
                r.requests,
                r.errors,
                r.p50,
                r.p95
            )?;
        }
        writeln!(w, "],\"skipped\":{}}}", skipped)?;
        Ok(())
    }

    fn json_escape(s: &str) -> String {
        let mut out = String::with_capacity(s.len());
        for c in s.chars() {
            match c {
                '"' => out.push_str("\\\""),
                '\\' => out.push_str("\\\\"),
                '\n' => out.push_str("\\n"),
                '\r' => out.push_str("\\r"),
                '\t' => out.push_str("\\t"),
                c if (c as u32) < 0x20 => {
                    out.push_str(&format!("\\u{:04x}", c as u32));
                }
                _ => out.push(c),
            }
        }
        out
    }
}

fn print_usage_and_exit(code: i32, msg: &str) -> ! {
    eprintln!("logstat: {}", msg);
    process::exit(code);
}

fn status_matches(status: u16, class: &str) -> bool {
    match class {
        "2xx" => (200..300).contains(&status),
        "3xx" => (300..400).contains(&status),
        "4xx" => (400..500).contains(&status),
        "5xx" => (500..600).contains(&status),
        _ => false,
    }
}

fn is_valid_status_class(s: &str) -> bool {
    VALID_STATUS_CLASSES.contains(&s)
}

fn read_entries(path: &str) -> io_result<(Vec<Entry>, usize)> {
    let file = File::open(path).map_err(|e| e.to_string())?;
    let reader = BufReader::new(file);
    let mut entries = Vec::new();
    let mut skipped = 0usize;
    for line_res in reader.lines() {
        let line = line_res.map_err(|e| e.to_string())?;
        if let Some(e) = parse::parse_line(&line) {
            entries.push(e);
        } else {
            // empty lines? split_whitespace gives 0 parts -> skipped. That is intended
            // But need to count every line that is not valid, including empty?
            // An empty line has 0 fields -> skipped
            skipped += 1;
        }
    }
    Ok((entries, skipped))
}

type io_result<T> = Result<T, String>;

fn run_summary(file: &str, json: bool) -> i32 {
    let (entries, skipped) = match read_entries(file) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("logstat: cannot read '{}': {}", file, e);
            return 1;
        }
    };
    let map = agg::aggregate(&entries);
    let rows = agg::sorted_rows(&map);

    let stdout = std::io::stdout();
    let mut out = stdout.lock();
    let res = if json {
        output::write_json(&mut out, &rows, skipped)
    } else {
        output::write_tsv(&mut out, &rows, skipped)
    };
    if res.is_err() {
        eprintln!("logstat: failed to write output");
        return 1;
    }
    0
}

fn run_filter(file: &str, status_class: &str, method_filter: Option<&str>) -> i32 {
    let (entries, _skipped) = match read_entries(file) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("logstat: cannot read '{}': {}", file, e);
            return 1;
        }
    };
    let stdout = std::io::stdout();
    let mut out = stdout.lock();
    for e in &entries {
        if !status_matches(e.status, status_class) {
            continue;
        }
        if let Some(m) = method_filter {
            if e.method != m {
                continue;
            }
        }
        if writeln!(out, "{}", e.normalized).is_err() {
            eprintln!("logstat: failed to write output");
            return 1;
        }
    }
    0
}

fn main() {
    let args: Vec<String> = env::args().collect();
    // args[0] is program name
    if args.len() < 2 {
        print_usage_and_exit(2, "missing subcommand (expected 'summary' or 'filter')");
    }
    let sub = args[1].as_str();
    match sub {
        "summary" => {
            // summary <file> [--json]
            if args.len() < 3 {
                print_usage_and_exit(2, "missing file argument for 'summary'");
            }
            let file = args[2].clone();
            if file.starts_with('-') {
                print_usage_and_exit(2, "missing file argument for 'summary'");
            }
            let mut json = false;
            if args.len() == 4 {
                if args[3] == "--json" {
                    json = true;
                } else {
                    print_usage_and_exit(2, &format!("unknown argument '{}' for 'summary'", args[3]));
                }
            } else if args.len() > 4 {
                print_usage_and_exit(2, "too many arguments for 'summary'");
            }
            let code = run_summary(&file, json);
            process::exit(code);
        }
        "filter" => {
            // filter <file> --status <class> [--method <METHOD>]
            if args.len() < 3 {
                print_usage_and_exit(2, "missing file argument for 'filter'");
            }
            let file = args[2].clone();
            if file.starts_with('-') {
                print_usage_and_exit(2, "missing file argument for 'filter'");
            }
            let mut status_class: Option<String> = None;
            let mut method_filter: Option<String> = None;
            let mut i = 3;
            while i < args.len() {
                match args[i].as_str() {
                    "--status" => {
                        if i + 1 >= args.len() {
                            print_usage_and_exit(2, "missing value for '--status'");
                        }
                        if status_class.is_some() {
                            print_usage_and_exit(2, "duplicate '--status'");
                        }
                        status_class = Some(args[i + 1].clone());
                        i += 2;
                    }
                    "--method" => {
                        if i + 1 >= args.len() {
                            print_usage_and_exit(2, "missing value for '--method'");
                        }
                        if method_filter.is_some() {
                            print_usage_and_exit(2, "duplicate '--method'");
                        }
                        method_filter = Some(args[i + 1].clone());
                        i += 2;
                    }
                    other => {
                        print_usage_and_exit(2, &format!("unknown argument '{}' for 'filter'", other));
                    }
                }
            }
            let sc = match status_class {
                Some(s) => s,
                None => print_usage_and_exit(2, "missing required '--status' for 'filter'"),
            };
            if !is_valid_status_class(&sc) {
                print_usage_and_exit(2, &format!("invalid --status class '{}' (expected 2xx, 3xx, 4xx, 5xx)", sc));
            }
            // validate method filter if present: if not in known list, we still allow but it will match nothing
            // No error for invalid method per spec
            let code = run_filter(&file, &sc, method_filter.as_deref());
            process::exit(code);
        }
        other => {
            print_usage_and_exit(2, &format!("unknown subcommand '{}'", other));
        }
    }
}
