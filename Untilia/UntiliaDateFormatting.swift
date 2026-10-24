//
//  UntiliaDateFormatting.swift
//  Untilia
//

import Foundation

@MainActor
enum UntiliaDateFormatting {
    private static var dateFormatters: [String: DateFormatter] = [:]
    private static var timeFormatters: [String: DateFormatter] = [:]

    static func dateString(_ date: Date, timeZone: TimeZone, abbreviatedMonth: Bool, language: AppLanguage) -> String {
        let key = "\(language.rawValue)-\(abbreviatedMonth ? "short" : "full")-\(timeZone.identifier)"
        let formatter: DateFormatter
        if let cached = dateFormatters[key] {
            formatter = cached
        } else {
            formatter = makeDateFormatter(template: abbreviatedMonth ? "dMMMy" : "dMMMMy", language: language)
            formatter.timeZone = timeZone
            dateFormatters[key] = formatter
        }
        return formatter.string(from: date)
    }

    static func timeString(_ date: Date, timeZone: TimeZone, language: AppLanguage, includingSeconds: Bool = false) -> String {
        let key = "\(language.rawValue)-\(includingSeconds ? "seconds" : "minutes")-\(timeZone.identifier)"
        let formatter: DateFormatter
        if let cached = timeFormatters[key] {
            formatter = cached
        } else {
            formatter = makeTimeFormatter(language: language, includingSeconds: includingSeconds)
            formatter.timeZone = timeZone
            timeFormatters[key] = formatter
        }
        return formatter.string(from: date)
    }

    static func utcOffsetString(for timeZone: TimeZone, at date: Date) -> String {
        let totalMinutes = timeZone.secondsFromGMT(for: date) / 60
        let sign = totalMinutes >= 0 ? "+" : "−"
        let hours = abs(totalMinutes) / 60
        let minutes = abs(totalMinutes) % 60
        return String(format: "UTC%@%02d:%02d", sign, hours, minutes)
    }

    static func timeZoneAbbreviationOrUTCOffset(for timeZone: TimeZone, at date: Date) -> String {
        if let abbreviation = timeZone.abbreviation(for: date),
           !abbreviation.isEmpty,
           !abbreviation.uppercased().hasPrefix("GMT") {
            return abbreviation
        }

        return utcOffsetString(for: timeZone, at: date)
    }

    private static func makeDateFormatter(template: String, language: AppLanguage) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }

    private static func makeTimeFormatter(language: AppLanguage, includingSeconds: Bool) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = includingSeconds ? "HH:mm:ss" : "HH:mm"
        return formatter
    }
}
