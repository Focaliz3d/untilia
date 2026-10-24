import Foundation
import Testing
@testable import Untilia

struct CalendarMonthSelectionTests {
    @Test func keepsRequestedYearsDaysAndLocalTimeAcrossHistoricalAndFutureZones() {
        for zone in ["Europe/Paris", "America/New_York", "Asia/Kathmandu"] {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: zone)!
            let selection = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 17, minute: 19))!
            for year in [1900, 1910, 1911, 2028, 2100, 2400, 2500] {
                for month in [1, 2, 7, 12] {
                    let first = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
                    let date = CalendarMonthSelection.date(in: first, preserving: selection, calendar: calendar)
                    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                    #expect(components.year == year)
                    #expect(components.month == month)
                    #expect(components.day == min(31, calendar.range(of: .day, in: .month, for: first)!.count))
                    #expect(components.hour == 17)
                    #expect(components.minute == 19)
                    #expect(components.second == 0)
                }
            }
        }
    }

    @Test func preservesExistingSpringAndAutumnDSTResolution() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        for (month, day) in [(3, 29), (10, 25)] {
            let selection = calendar.date(from: DateComponents(year: 2026, month: 1, day: day, hour: 2, minute: 30))!
            let first = calendar.date(from: DateComponents(year: 2026, month: month, day: 1))!
            let selectedDay = calendar.date(bySetting: .day, value: day, of: first)!
            let previousBehavior = calendar.date(bySettingHour: 2, minute: 30, second: 0, of: selectedDay)!
            #expect(CalendarMonthSelection.date(in: first, preserving: selection, calendar: calendar) == previousBehavior)
        }
    }
}
