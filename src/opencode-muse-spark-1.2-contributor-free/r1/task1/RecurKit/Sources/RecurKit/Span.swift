import Foundation

/// A half-open time span `[start, end)`. Spans with `end <= start` are
/// invalid and refused at construction.
public struct Span: Equatable, Comparable, Sendable {
    public let start: Date
    public let end: Date

    public init?(start: Date, end: Date) {
        guard end > start else { return nil }
        self.start = start
        self.end = end
    }

    /// Duration in seconds.
    public var duration: TimeInterval { end.timeIntervalSince(start) }

    /// Whether `date` falls inside the span (half-open: the end instant
    /// is NOT contained).
    public func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    /// Whether two spans share at least one instant. Touching spans
    /// (`a.end == b.start`) do NOT overlap — the shared boundary belongs
    /// to neither, by half-open convention.
    public func overlaps(_ other: Span) -> Bool {
        start < other.end && other.start < end
    }

    /// Whether two spans overlap or touch exactly at a boundary — the
    /// condition under which their union is a single span.
    public func abuts(_ other: Span) -> Bool {
        start <= other.end && other.start <= end
    }

    /// The overlapping portion of two spans, if any.
    public func intersection(_ other: Span) -> Span? {
        Span(start: max(start, other.start), end: min(end, other.end))
    }

    /// This span clamped into `bounds`, or nil if nothing survives.
    public func clamped(to bounds: Span) -> Span? {
        intersection(bounds)
    }

    public static func < (lhs: Span, rhs: Span) -> Bool {
        if lhs.start != rhs.start { return lhs.start < rhs.start }
        return lhs.end < rhs.end
    }
}
