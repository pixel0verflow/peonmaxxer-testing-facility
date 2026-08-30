import Foundation
import RecurKit

func date(_ s: TimeInterval) -> Date { Date(timeIntervalSince1970: s) }
func span(_ a: TimeInterval, _ b: TimeInterval) -> Span { Span(start: date(a), end: date(b))! }

let spanChecks: [Check] = [
    check("invalid spans are refused") { t in
        t.expect(Span(start: date(100), end: date(100)) == nil, "zero-length span must be nil")
        t.expect(Span(start: date(100), end: date(50)) == nil, "inverted span must be nil")
    },
    check("contains is half-open") { t in
        let s = span(100, 200)
        t.expect(s.contains(date(100)), "start is contained")
        t.expect(s.contains(date(199)), "interior is contained")
        t.expect(!s.contains(date(200)), "end is NOT contained")
    },
    check("touching spans do not overlap but do abut") { t in
        let a = span(0, 100), b = span(100, 200)
        t.expect(!a.overlaps(b), "touching spans must not overlap")
        t.expect(a.abuts(b), "touching spans must abut")
    },
    check("intersection and clamp") { t in
        let a = span(0, 100), b = span(50, 150)
        t.equal(a.intersection(b), span(50, 100), "intersection")
        t.expect(a.intersection(span(100, 110)) == nil, "touching spans have no intersection")
        t.equal(b.clamped(to: a), span(50, 100), "clamp")
    },
]

let spanSetChecks: [Check] = [
    check("insert coalesces overlapping and touching spans") { t in
        var set = SpanSet()
        set.insert(span(0, 100))
        set.insert(span(200, 300))
        set.insert(span(90, 200)) // bridges both
        t.equal(set.spans, [span(0, 300)], "coalesced spans")
    },
    check("disjoint inserts keep ascending order") { t in
        let set = SpanSet([span(200, 300), span(0, 100)])
        t.equal(set.spans, [span(0, 100), span(200, 300)], "ordering")
        t.equal(set.totalDuration, 200, "totalDuration")
    },
    check("gaps are clipped to bounds") { t in
        let set = SpanSet([span(100, 200), span(300, 400)])
        t.equal(set.gaps(in: span(0, 500)), [span(0, 100), span(200, 300), span(400, 500)], "full window")
        t.equal(set.gaps(in: span(150, 350)), [span(200, 300)], "inner window")
        t.equal(set.gaps(in: span(100, 400)), [span(200, 300)], "exact window")
    },
    check("contains reports coverage") { t in
        let set = SpanSet([span(0, 10), span(20, 30)])
        t.expect(set.contains(date(5)), "covered instant")
        t.expect(!set.contains(date(15)), "gap instant")
        t.expect(!set.contains(date(10)), "half-open end")
    },
]
