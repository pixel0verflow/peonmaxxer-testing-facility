import Foundation
import RecurKit

private var warsawDST: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Warsaw")!
    return c
}

private func localDST(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int = 0) -> Date {
    DateComponents(calendar: warsawDST, year: y, month: mo, day: d, hour: h, minute: mi).date!
}

private func wallHour(_ date: Date, calendar: Calendar) -> Int {
    calendar.component(.hour, from: date)
}

let dstRegressionChecks: [Check] = [
    check("weekly occurrences preserve wall time across spring DST (Europe/Warsaw)") { t in
        // Monday 2024-03-25 09:00 CET, weekly recurrences should stay 09:00 wall time after DST starts Mar 31
        let rule = Recurrence(start: localDST(2024, 3, 25, 9), frequency: .weekly, bound: .count(3), calendar: warsawDST)!
        let expected = [localDST(2024, 3, 25, 9), localDST(2024, 4, 1, 9), localDST(2024, 4, 8, 9)]
        t.equal(rule.occurrences(), expected, "weekly spring DST")
        // Explicit wall-hour check for clarity if dates differ by offset
        for d in rule.occurrences() {
            t.expect(wallHour(d, calendar: warsawDST) == 9, "wall hour should be 9 but was \(wallHour(d, calendar: warsawDST)) for \(d)")
        }
    },
    check("daily occurrences preserve wall time across spring DST (Europe/Warsaw)") { t in
        // Daily starting Mar 29 09:00 across DST transition Mar 31 02:00->03:00
        let rule = Recurrence(start: localDST(2024, 3, 29, 9), frequency: .daily, bound: .count(5), calendar: warsawDST)!
        let expected = [
            localDST(2024, 3, 29, 9),
            localDST(2024, 3, 30, 9),
            localDST(2024, 3, 31, 9),
            localDST(2024, 4, 1, 9),
            localDST(2024, 4, 2, 9),
        ]
        t.equal(rule.occurrences(), expected, "daily spring DST")
        for d in rule.occurrences() {
            t.expect(wallHour(d, calendar: warsawDST) == 9, "wall hour should be 9 but was \(wallHour(d, calendar: warsawDST))")
        }
    },
    check("daily occurrences preserve wall time across autumn DST (Europe/Warsaw)") { t in
        // DST ends Oct 27 2024 03:00 -> 02:00, daily should stay 09:00
        let rule = Recurrence(start: localDST(2024, 10, 25, 9), frequency: .daily, bound: .count(5), calendar: warsawDST)!
        let expected = [
            localDST(2024, 10, 25, 9),
            localDST(2024, 10, 26, 9),
            localDST(2024, 10, 27, 9),
            localDST(2024, 10, 28, 9),
            localDST(2024, 10, 29, 9),
        ]
        t.equal(rule.occurrences(), expected, "daily autumn DST")
        for d in rule.occurrences() {
            t.expect(wallHour(d, calendar: warsawDST) == 9, "wall hour should be 9 but was \(wallHour(d, calendar: warsawDST))")
        }
    },
    check("weekly occurrences preserve wall time across autumn DST (Europe/Warsaw)") { t in
        // Weekly Mondays across autumn transition
        let rule = Recurrence(start: localDST(2024, 10, 21, 9), frequency: .weekly, bound: .count(3), calendar: warsawDST)!
        let expected = [localDST(2024, 10, 21, 9), localDST(2024, 10, 28, 9), localDST(2024, 11, 4, 9)]
        t.equal(rule.occurrences(), expected, "weekly autumn DST")
        for d in rule.occurrences() {
            t.expect(wallHour(d, calendar: warsawDST) == 9, "wall hour should be 9 but was \(wallHour(d, calendar: warsawDST))")
        }
    },
]
