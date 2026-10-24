import Foundation
import Testing
@testable import Untilia

@MainActor
struct UntiliaDateFormattingTests {
    @Test func cachedFormattersKeepZonesLanguagesAndSeasonalOffsetsIndependent() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let dates = [1, 7].map {
            calendar.date(from: DateComponents(year: 2026, month: $0, day: 15, hour: 23, minute: 59, second: 58))!
        }
        let zones = ["Europe/Paris", "America/New_York", "Australia/Adelaide", "Asia/Tokyo"].map { TimeZone(identifier: $0)! }
        for _ in 0..<3 {
            for date in dates {
                for language in AppLanguage.allCases {
                    for zone in zones {
                        for seconds in [false, true] {
                            let expected = DateFormatter()
                            expected.locale = language.locale
                            expected.timeZone = zone
                            expected.dateFormat = seconds ? "HH:mm:ss" : "HH:mm"
                            #expect(UntiliaDateFormatting.timeString(date, timeZone: zone, language: language, includingSeconds: seconds) == expected.string(from: date))
                        }
                        for abbreviated in [false, true] {
                            let expected = DateFormatter()
                            expected.locale = language.locale
                            expected.timeZone = zone
                            expected.setLocalizedDateFormatFromTemplate(abbreviated ? "dMMMy" : "dMMMMy")
                            #expect(UntiliaDateFormatting.dateString(date, timeZone: zone, abbreviatedMonth: abbreviated, language: language) == expected.string(from: date))
                        }
                    }
                }
            }
        }
    }
}
