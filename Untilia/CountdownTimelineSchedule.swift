import SwiftUI

/// Refreshes on wall-clock second boundaries, without work behind a presented screen.
struct CountdownTimelineSchedule: TimelineSchedule {
    let isPaused: Bool

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnySequence<Date> {
        guard !isPaused else { return AnySequence([startDate]) }
        return AnySequence {
            // Render immediately, then align with the system clock rather than
            // preserving the fractional second at which this screen was opened.
            var nextDate = startDate
            return AnyIterator<Date> {
                let date = nextDate
                nextDate = Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded(.down) + 1)
                return date
            }
        }
    }
}
