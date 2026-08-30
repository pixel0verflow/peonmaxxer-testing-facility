import Foundation

/// A minimal check harness: register checks, run them all, exit nonzero
/// if any expectation failed. Add a new check with `check("name") { t in
/// t.expect(..., "message") }` in any *Checks.swift file and list it in
/// main.swift.
final class T {
    private(set) var failures: [String] = []

    func expect(_ condition: Bool, _ message: @autoclosure () -> String) {
        if !condition { failures.append(message()) }
    }

    func equal<V: Equatable>(_ got: V, _ want: V, _ label: String) {
        if got != want { failures.append("\(label): got \(got), want \(want)") }
    }
}

struct Check {
    let name: String
    let body: (T) -> Void
}

func check(_ name: String, _ body: @escaping (T) -> Void) -> Check {
    Check(name: name, body: body)
}

func runChecks(_ checks: [Check]) -> Never {
    var failed = 0
    for c in checks {
        let t = T()
        c.body(t)
        if t.failures.isEmpty {
            print("PASS \(c.name)")
        } else {
            failed += 1
            print("FAIL \(c.name)")
            for f in t.failures { print("     \(f)") }
        }
    }
    print("\(checks.count - failed)/\(checks.count) checks passed")
    exit(failed == 0 ? 0 : 1)
}
