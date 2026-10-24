//
//  AppLocalization.swift
//  Untilia
//

import Foundation
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: self == .french ? "fr_FR" : "en_GB")
    }

    var flag: String {
        self == .french ? "🇫🇷" : "🇬🇧"
    }

    var nativeName: String {
        self == .french ? "Français" : "English"
    }

    static var detectedFromSystem: AppLanguage {
        let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? ""
        return preferredLanguage.hasPrefix("fr") ? .french : .english
    }
}

final class AppLanguageStore: ObservableObject {
    private static let languageKey = "daysLeft.appLanguage"
    private let userDefaults: UserDefaults

    @Published private(set) var language: AppLanguage

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let rawValue = userDefaults.string(forKey: Self.languageKey),
           let savedLanguage = AppLanguage(rawValue: rawValue) {
            language = savedLanguage
        } else {
            let detectedLanguage = AppLanguage.detectedFromSystem
            language = detectedLanguage
            userDefaults.set(detectedLanguage.rawValue, forKey: Self.languageKey)
        }
    }

    func setLanguage(_ language: AppLanguage) {
        guard self.language != language else { return }
        self.language = language
        userDefaults.set(language.rawValue, forKey: Self.languageKey)
    }
}

enum L10n {
    enum Key {
        case settings
        case about
        case aboutTagline
        case aboutDescription
        case supportAndPrivacy
        case supportAndPrivacyDescription
        case language
        case deadline
        case start
        case deadlineTime
        case startTime
        case localTimeInTimeZone
        case clockLocal
        case clockDeadline
        case clockStart
        case clockHidden
        case cycleClock
        case timeZone
        case cityOrRegion
        case useLocalTimeZone
        case returnToToday
        case chooseMonthAndYear
        case chooseTimeZone
        case dateConfirmed
        case saveChanges
        case deadlinePassed
        case startUnavailable
        case countdownName
        case name
        case nameOnCard
        case confirmName
        case month
        case year
        case hours
        case minutes
        case close
        case unsavedChanges
        case stayInSettings
        case leaveWithoutSaving
        case unsavedChangesMessage
        case displayedDate
        case showDate
        case now
        case until
        case since
        case timeLeft
        case timeElapsed
        case dateReached
        case progress
        case progressSince
        case deadlineReached
        case done
    }

    enum Unit {
        case years
        case months
        case weeks
        case days
        case hours
        case minutes
        case seconds
    }

    static func text(_ key: Key, language: AppLanguage) -> String {
        switch key {
        case .settings: language == .english ? "Settings" : "Paramètres"
        case .about: language == .english ? "About" : "À propos"
        case .aboutTagline: language == .english ? "Time, at your pace." : "Le temps, à votre rythme."
        case .aboutDescription: language == .english ? "The time left until your next milestone. The time elapsed since a meaningful moment." : "Le temps restant avant votre prochaine échéance. Le temps écoulé depuis un moment important."
        case .supportAndPrivacy: language == .english ? "Support & privacy" : "Assistance et confidentialité"
        case .supportAndPrivacyDescription: language == .english ? "Get in touch or read our privacy policy." : "Contactez-nous ou consultez notre politique de confidentialité."
        case .language: language == .english ? "Language" : "Langue"
        case .deadline: language == .english ? "Deadline" : "Échéance"
        case .start: language == .english ? "Start" : "Départ"
        case .deadlineTime: language == .english ? "Deadline time" : "Heure de l’échéance"
        case .startTime: language == .english ? "Start time" : "Heure de départ"
        case .localTimeInTimeZone: language == .english ? "Local time in this time zone" : "Heure locale dans ce fuseau"
        case .clockLocal: language == .english ? "Local time" : "Heure locale"
        case .clockDeadline: language == .english ? "Current time in the deadline time zone" : "Heure actuelle dans le fuseau de l’échéance"
        case .clockStart: language == .english ? "Current time in the start time zone" : "Heure actuelle dans le fuseau du départ"
        case .clockHidden: language == .english ? "Clock hidden" : "Horloge masquée"
        case .cycleClock: language == .english ? "Tap to cycle through local, deadline and start time zones, or hide the clock. Tap the dot to show local time again." : "Touchez pour parcourir les fuseaux local, d’échéance et de départ, ou masquer l’horloge. Touchez le point pour retrouver l’heure locale."
        case .timeZone: language == .english ? "Time zone" : "Fuseau horaire"
        case .cityOrRegion: language == .english ? "City or region" : "Ville ou région"
        case .useLocalTimeZone: language == .english ? "Use local time zone" : "Utiliser le fuseau horaire local"
        case .returnToToday: language == .english ? "Return to today" : "Revenir à la date d’aujourd’hui"
        case .chooseMonthAndYear: language == .english ? "Choose month and year" : "Choisir le mois et l’année"
        case .chooseTimeZone: language == .english ? "Choose time zone" : "Choisir le fuseau horaire"
        case .dateConfirmed: language == .english ? "Date confirmed" : "Date validée"
        case .saveChanges: language == .english ? "Save changes" : "Enregistrer les modifications"
        case .deadlinePassed: language == .english ? "DEADLINE PASSED" : "ÉCHÉANCE PASSÉE"
        case .startUnavailable: language == .english ? "Start unavailable because the deadline has passed" : "Départ indisponible car l’échéance est passée"
        case .countdownName: language == .english ? "Countdown name" : "Nom de l’échéance"
        case .name: language == .english ? "NAME" : "NOM"
        case .nameOnCard: language == .english ? "This name will appear on its card" : "Ce nom apparaîtra sur sa carte"
        case .confirmName: language == .english ? "Confirm name" : "Valider le nom"
        case .month: language == .english ? "Month" : "Mois"
        case .year: language == .english ? "Year" : "Année"
        case .hours: language == .english ? "Hours" : "Heures"
        case .minutes: language == .english ? "Minutes" : "Minutes"
        case .close: language == .english ? "Close" : "Fermer"
        case .unsavedChanges: language == .english ? "Unsaved changes" : "Modifications non enregistrées"
        case .stayInSettings: language == .english ? "Stay in Settings" : "Rester dans les paramètres"
        case .leaveWithoutSaving: language == .english ? "Leave without saving" : "Quitter sans enregistrer"
        case .unsavedChangesMessage: language == .english
            ? "One or more dates have been changed. If you leave now, these changes will be lost."
            : "Une ou plusieurs dates ont été modifiées. Si vous quittez maintenant, ces changements seront perdus."
        case .displayedDate: language == .english ? "Displayed date" : "Date affichée"
        case .showDate: language == .english ? "Show this date" : "Afficher cette date"
        case .now: language == .english ? "IT’S NOW" : "C’EST MAINTENANT"
        case .until: language == .english ? "until" : "jusqu’au"
        case .since: language == .english ? "since" : "depuis le"
        case .timeLeft: language == .english ? "TIME LEFT" : "IL RESTE"
        case .timeElapsed: language == .english ? "TIME ELAPSED" : "IL S’EST ÉCOULÉ"
        case .dateReached: language == .english ? "DATE REACHED" : "DATE ATTEINTE"
        case .progress: language == .english ? "PROGRESS" : "PROGRESSION"
        case .progressSince: language == .english ? "PROGRESS SINCE" : "PROGRESSION DEPUIS LE"
        case .deadlineReached: language == .english ? "DEADLINE REACHED" : "ÉCHÉANCE ATTEINTE"
        case .done: language == .english ? "DONE" : "TERMINÉ"
        }
    }

    static func themeTitle(_ theme: UntiliaTheme, language: AppLanguage) -> String {
        switch theme {
        case .twilight: language == .english ? "Twilight" : "Crépuscule"
        case .forest: language == .english ? "Forest" : "Forêt"
        case .dunes: "Dunes"
        }
    }

    static func fallbackDate(_ index: Int, language: AppLanguage) -> String {
        "Date \(index)"
    }

    static func unit(_ value: Int, _ unit: Unit, language: AppLanguage, uppercase: Bool = false) -> String {
        "\(value) \(unitName(value, unit, language: language, uppercase: uppercase))"
    }

    static func unitName(_ value: Int, _ unit: Unit, language: AppLanguage, uppercase: Bool = false) -> String {
        let singular: String
        let plural: String

        switch (language, unit) {
        case (.french, .years): (singular, plural) = ("AN", "ANS")
        case (.french, .months): (singular, plural) = ("MOIS", "MOIS")
        case (.french, .weeks): (singular, plural) = ("SEMAINE", "SEMAINES")
        case (.french, .days): (singular, plural) = ("JOUR", "JOURS")
        case (.french, .hours): (singular, plural) = ("HEURE", "HEURES")
        case (.french, .minutes): (singular, plural) = ("MINUTE", "MINUTES")
        case (.french, .seconds): (singular, plural) = ("SECONDE", "SECONDES")
        case (.english, .years): (singular, plural) = ("YEAR", "YEARS")
        case (.english, .months): (singular, plural) = ("MONTH", "MONTHS")
        case (.english, .weeks): (singular, plural) = ("WEEK", "WEEKS")
        case (.english, .days): (singular, plural) = ("DAY", "DAYS")
        case (.english, .hours): (singular, plural) = ("HOUR", "HOURS")
        case (.english, .minutes): (singular, plural) = ("MINUTE", "MINUTES")
        case (.english, .seconds): (singular, plural) = ("SECOND", "SECONDS")
        }

        let result = value == 1 ? singular : plural
        return uppercase ? result.uppercased() : result
    }

    static func shortUnit(_ value: Int, _ unit: Unit, language: AppLanguage) -> String? {
        guard value > 0 else { return nil }

        switch unit {
        case .months:
            return language == .english ? "\(value) \(value == 1 ? "month" : "months")" : "\(value) mois"
        case .weeks:
            return language == .english ? "\(value) wk." : "\(value) sem."
        case .days:
            return language == .english ? "\(value) \(value == 1 ? "day" : "days")" : "\(value) \(value == 1 ? "jour" : "jours")"
        case .hours:
            return "\(value) h"
        case .minutes:
            return "\(value) min"
        case .seconds:
            return "\(value) s"
        case .years:
            return L10n.unit(value, .years, language: language)
        }
    }

    static func cardAccessibility(name: String, date: String, time: String, timeZone: String, theme: String, language: AppLanguage) -> String {
        language == .english
            ? "\(name), \(date), \(time), time zone \(timeZone), theme \(theme)"
            : "\(name), \(date), \(time), fuseau \(timeZone), thème \(theme)"
    }

    static func elapsedAccessibility(date: String, time: String, timeZone: String, language: AppLanguage) -> String {
        language == .english
            ? "Deadline reached on \(date) at \(time), time zone \(timeZone)"
            : "Échéance atteinte le \(date) à \(time), fuseau \(timeZone)"
    }

    static func progressAccessibility(date: String, time: String, timeZone: String, percent: Int, language: AppLanguage) -> String {
        language == .english
            ? "Progress since \(date) at \(time), time zone \(timeZone), \(percent) percent"
            : "Progression depuis le \(date) à \(time), fuseau \(timeZone), \(percent) pour cent"
    }

    static func dateCardEditorAccessibility(name: String, index: Int, language: AppLanguage) -> String {
        language == .english ? "Edit \(name), date \(index)" : "Modifier \(name), date \(index)"
    }

    static func editNameAccessibility(name: String, language: AppLanguage) -> String {
        language == .english ? "Countdown name: \(name)" : "Nom de la date : \(name)"
    }

    static func editDateAccessibility(title: String, date: String, time: String, timeZone: String, language: AppLanguage) -> String {
        language == .english
            ? "Edit \(title.lowercased()): \(date), \(time), time zone \(timeZone)"
            : "Modifier \(title.lowercased()) : \(date), \(time), fuseau \(timeZone)"
    }

    static func setNowAccessibility(title: String, language: AppLanguage) -> String {
        language == .english ? "Set \(title.lowercased()) to now" : "Définir \(title.lowercased()) à maintenant"
    }

    static func resetMidnightAccessibility(title: String, language: AppLanguage) -> String {
        language == .english ? "Reset \(title.lowercased()) to 00:00" : "Remettre \(title.lowercased()) à 00:00"
    }

    static func timeAccessibility(title: String, time: String, language: AppLanguage) -> String {
        language == .english ? "\(title): \(time)" : "\(title) : \(time)"
    }

    static func timeZoneAccessibility(city: String, offset: String, language: AppLanguage) -> String {
        language == .english ? "Choose time zone: \(city), \(offset)" : "Choisir le fuseau horaire : \(city), \(offset)"
    }

    static func countdownAccessibility(snapshot: CountdownSnapshot, language: AppLanguage) -> String {
        if snapshot.isElapsed {
            return [
                unit(snapshot.yearsRemaining, .years, language: language),
                unit(snapshot.monthsAfterYearsRemaining, .months, language: language),
                unit(snapshot.weeksAfterMonthsRemaining, .weeks, language: language),
                unit(snapshot.daysAfterWeeksRemaining, .days, language: language),
                unit(snapshot.hoursAfterCalendarUnitsRemaining, .hours, language: language),
                unit(snapshot.remainingMinutes, .minutes, language: language),
                unit(snapshot.remainingSeconds, .seconds, language: language)
            ].joined(separator: language == .english ? ", " : ", ") + (language == .english ? " elapsed since the deadline" : " écoulées depuis l’échéance")
        }

        if snapshot.isReached {
            return text(.dateReached, language: language)
        }

        return [
            unit(snapshot.yearsRemaining, .years, language: language),
            unit(snapshot.monthsAfterYearsRemaining, .months, language: language),
            unit(snapshot.weeksAfterMonthsRemaining, .weeks, language: language),
            unit(snapshot.daysAfterWeeksRemaining, .days, language: language),
            unit(snapshot.hoursAfterCalendarUnitsRemaining, .hours, language: language),
            unit(snapshot.remainingMinutes, .minutes, language: language),
            unit(snapshot.remainingSeconds, .seconds, language: language)
        ].joined(separator: ", ") + (language == .english ? " remaining" : " restantes")
    }
}
