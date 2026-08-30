import Foundation
import RecurKit

private var warsaw: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Warsaw")!
    return c
}

private func local(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int = 0) -> Date {
    DateComponents(calendar: warsaw, year: y, month: mo, day: d, hour: h, minute: mi).date!
}

let recurrenceChecks: [Check] = [
    check("daily count produces exactly n occurrences") { t in
        let rule = Recurrence(start: local(2024, 1, 10, 9), frequency: .daily, bound: .count(3), calendar: warsaw)!
        t.equal(rule.occurrences(), [local(2024, 1, 10, 9), local(2024, 1, 11, 9), local(2024, 1, 12, 9)], "occurrences")
    },
    check("until bound is exclusive") { t in
        let rule = Recurrence(start: local(2024, 1, 10, 9), frequency: .daily,
                              bound: .until(local(2024, 1, 12, 9)), calendar: warsaw)!
        t.equal(rule.occurrences().count, 2, "count")
    },
    check("interval skips periods") { t in
        let rule = Recurrence(start: local(2024, 1, 1, 12), frequency: .daily, interval: 3,
                              bound: .count(3), calendar: warsaw)!
        t.equal(rule.occurrences(), [local(2024, 1, 1, 12), local(2024, 1, 4, 12), local(2024, 1, 7, 12)], "occurrences")
    },
    check("invalid rules are refused") { t in
        t.expect(Recurrence(start: .init(), frequency: .daily, interval: 0, bound: .count(1), calendar: warsaw) == nil, "interval 0")
        t.expect(Recurrence(start: .init(), frequency: .weekly, bound: .count(0), calendar: warsaw) == nil, "count 0")
    },
    check("occurrences filtered to a window") { t in
        let rule = Recurrence(start: local(2024, 1, 1, 8), frequency: .daily, bound: .count(10), calendar: warsaw)!
        let window = Span(start: local(2024, 1, 3, 0), end: local(2024, 1, 6, 0))!
        t.equal(rule.occurrences(in: window), [local(2024, 1, 3, 8), local(2024, 1, 4, 8), local(2024, 1, 5, 8)], "window")
    },
    check("spans expand each occurrence") { t in
        let rule = Recurrence(start: local(2024, 1, 10, 9), frequency: .daily, bound: .count(2), calendar: warsaw)!
        let spans = rule.spans(duration: 1800)
        t.equal(spans.count, 2, "span count")
        t.equal(spans[0].duration, 1800, "span duration")
        t.equal(spans[1].start, local(2024, 1, 11, 9), "second span start")
    },
]
