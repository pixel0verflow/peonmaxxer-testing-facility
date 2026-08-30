import Foundation

/// A normalized set of non-overlapping, non-touching spans kept in
/// ascending order. Inserting a span that overlaps or touches existing
/// members coalesces them into one.
public struct SpanSet: Equatable, Sendable {
    public private(set) var spans: [Span] = []

    public init() {}

    public init(_ spans: [Span]) {
        for span in spans { insert(span) }
    }

    /// Inserts `span`, merging it with every member it overlaps or
    /// touches, preserving order and normalization.
    public mutating func insert(_ span: Span) {
        var merged = span
        var out: [Span] = []
        var placed = false
        for existing in spans {
            if existing.abuts(merged) {
                merged = Span(
                    start: min(existing.start, merged.start),
                    end: max(existing.end, merged.end)
                )!
            } else if existing.end <= merged.start {
                out.append(existing)
            } else {
                if !placed {
                    out.append(merged)
                    placed = true
                }
                out.append(existing)
            }
        }
        if !placed { out.append(merged) }
        spans = out
    }

    /// Total covered duration, in seconds.
    public var totalDuration: TimeInterval {
        spans.reduce(0) { $0 + $1.duration }
    }

    /// The uncovered spans between members, clipped to `bounds`.
    public func gaps(in bounds: Span) -> [Span] {
        var result: [Span] = []
        var cursor = bounds.start
        for span in spans {
            guard span.start < bounds.end, span.end > bounds.start else { continue }
            if span.start > cursor, let gap = Span(start: cursor, end: min(span.start, bounds.end)) {
                result.append(gap)
            }
            cursor = max(cursor, span.end)
        }
        if cursor < bounds.end, let tail = Span(start: cursor, end: bounds.end) {
            result.append(tail)
        }
        return result
    }

    /// Whether `date` is covered by any member span.
    public func contains(_ date: Date) -> Bool {
        spans.contains { $0.contains(date) }
    }
}
