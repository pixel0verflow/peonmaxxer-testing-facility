import Foundation

/// A recurrence rule: a start instant repeated on a fixed cadence in a
/// specific calendar, bounded by a count or an end instant.
///
/// Occurrences are CALENDAR times, not raw instants: "every week at
/// 09:00" means 09:00 on the local wall clock of `calendar.timeZone`,
/// whatever the UTC offset happens to be that week.
public struct Recurrence: Sendable {
    public enum Frequency: Sendable {
        case daily
        case weekly
    }

    public enum Bound: Sendable {
        /// At most `n` occurrences (including the first).
        case count(Int)
        /// Occurrences strictly before this instant.
        case until(Date)
    }

    public let start: Date
    public let frequency: Frequency
    /// Every `interval` days/weeks; must be >= 1.
    public let interval: Int
    public let bound: Bound
    public let calendar: Calendar

    public init?(start: Date, frequency: Frequency, interval: Int = 1, bound: Bound, calendar: Calendar) {
        guard interval >= 1 else { return nil }
        if case .count(let n) = bound, n < 1 { return nil }
        self.start = start
        self.frequency = frequency
        self.interval = interval
        self.bound = bound
        self.calendar = calendar
    }

    /// The stride between occurrences, in seconds.
    private var strideSeconds: TimeInterval {
        switch frequency {
        case .daily: return TimeInterval(86_400 * interval)
        case .weekly: return TimeInterval(7 * 86_400 * interval)
        }
    }

    /// All occurrences the rule produces, in order.
    public func occurrences() -> [Date] {
        var result: [Date] = []
        var current = start
        while true {
            switch bound {
            case .count(let n):
                if result.count >= n { return result }
            case .until(let limit):
                if current >= limit { return result }
            }
            result.append(current)
            current = current.addingTimeInterval(strideSeconds)
        }
    }

    /// Occurrences that fall inside `window` (half-open).
    public func occurrences(in window: Span) -> [Date] {
        occurrences().filter { window.contains($0) }
    }

    /// Each occurrence expanded into a span of `duration` seconds.
    public func spans(duration: TimeInterval) -> [Span] {
        occurrences().compactMap { Span(start: $0, end: $0.addingTimeInterval(duration)) }
    }
}
