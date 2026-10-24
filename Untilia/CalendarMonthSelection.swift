import Foundation

enum CalendarMonthSelection {
    static func date(in month: Date, preserving selection: Date, calendar: Calendar) -> Date {
        let selectedDay = calendar.component(.day, from: selection)
        let lastDay = calendar.range(of: .day, in: .month, for: month)?.count ?? selectedDay
        let day = min(selectedDay, lastDay)
        let dateWithSelectedDay = calendar.date(bySetting: .day, value: day, of: month) ?? month
        let hour = calendar.component(.hour, from: selection)
        let minute = calendar.component(.minute, from: selection)
        if let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dateWithSelectedDay) {
            // Keep the existing handling of missing/repeated DST hours.
            return date
        }
        // Historical offsets may include seconds (Paris: +00:09:21 before
        // 1911). Calendar's hour matcher can fail there, unlike construction
        // from local components. Never fall back to the previous selected year.
        var components = calendar.dateComponents([.era, .year, .month], from: month)
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? selection
    }
}
