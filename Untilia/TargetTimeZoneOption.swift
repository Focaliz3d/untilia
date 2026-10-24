import Foundation

struct TargetTimeZoneOption: Identifiable, Sendable {
    let identifier: String

    var id: String { identifier }

    nonisolated var city: String {
        Self.cityName(for: identifier)
    }

    nonisolated static func cityName(for identifier: String) -> String {
        identifier == "UTC"
            ? "UTC"
            : identifier.split(separator: "/").last.map { String($0).replacingOccurrences(of: "_", with: " ") } ?? identifier
    }

    nonisolated var region: String {
        identifier.split(separator: "/").dropLast().joined(separator: " · ")
    }

    nonisolated var searchableText: String {
        "\(city) \(region) \(identifier)"
    }

    nonisolated static func loadAll() -> [TargetTimeZoneOption] {
        let legacyPrefixes = ["Etc/", "SystemV/", "US/", "Canada/", "Mexico/", "Brazil/", "Chile/"]
        let cities = TimeZone.knownTimeZoneIdentifiers
            .filter { identifier in
                identifier.contains("/") && !legacyPrefixes.contains(where: identifier.hasPrefix)
            }
            .map(TargetTimeZoneOption.init(identifier:))
            .sorted {
                $0.city.localizedStandardCompare($1.city) == .orderedAscending
            }
        return [TargetTimeZoneOption(identifier: "UTC")] + cities
    }
}
