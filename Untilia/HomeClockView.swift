import SwiftUI

enum HomeClockMode: String, CaseIterable {
    case local
    case deadline
    case start
    case hidden
}

/// The clock changes presentation only; countdown dates and calculations stay untouched.
struct HomeClockCycle {
    let localTimeZone: TimeZone
    let deadlineTimeZone: TimeZone
    let startTimeZone: TimeZone
    let referenceDate: Date

    init(localTimeZone: TimeZone, deadlineTimeZone: TimeZone, startTimeZone: TimeZone, referenceDate: Date = Date()) {
        self.localTimeZone = localTimeZone
        self.deadlineTimeZone = deadlineTimeZone
        self.startTimeZone = startTimeZone
        self.referenceDate = referenceDate
    }

    var modes: [HomeClockMode] {
        var offsets: Set<Int> = [localTimeZone.secondsFromGMT(for: referenceDate)]
        var result: [HomeClockMode] = [.local]
        // The clock shows the current instant. Different cities with the same
        // current UTC offset must not add identical clock readings to the cycle.
        if offsets.insert(deadlineTimeZone.secondsFromGMT(for: referenceDate)).inserted { result.append(.deadline) }
        if offsets.insert(startTimeZone.secondsFromGMT(for: referenceDate)).inserted { result.append(.start) }
        return result + [.hidden]
    }

    func resolvedMode(_ preferred: HomeClockMode) -> HomeClockMode {
        if modes.contains(preferred) { return preferred }
        if preferred == .start,
           startTimeZone.secondsFromGMT(for: referenceDate) == deadlineTimeZone.secondsFromGMT(for: referenceDate),
           modes.contains(.deadline) { return .deadline }
        return .local
    }

    func next(after preferred: HomeClockMode) -> HomeClockMode {
        let available = modes
        let index = available.firstIndex(of: resolvedMode(preferred)) ?? 0
        return available[(index + 1) % available.count]
    }

    func timeZone(for preferred: HomeClockMode) -> TimeZone? {
        switch resolvedMode(preferred) {
        case .local: localTimeZone
        case .deadline: deadlineTimeZone
        case .start: startTimeZone
        case .hidden: nil
        }
    }
}

struct HomeClockView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @AppStorage("daysLeft.homeClockMode") private var storedMode = HomeClockMode.local.rawValue
    let theme: UntiliaTheme
    let deadlineTimeZone: TimeZone
    let startTimeZone: TimeZone
    let isPaused: Bool
    let leadingInset: CGFloat

    private var preferredMode: HomeClockMode { HomeClockMode(rawValue: storedMode) ?? .local }

    var body: some View {
        // A hidden clock does not need a one-second timeline. Showing it again
        // resumes at the current instant, aligned to the system's next second.
        TimelineView(CountdownTimelineSchedule(isPaused: isPaused || preferredMode == .hidden)) { context in
            clockButton(at: context.date)
        }
        .transaction {
            // AppStorage notifications and timeline updates can arrive outside
            // the tap's transaction: keep every clock update instantaneous.
            $0.animation = nil
            $0.disablesAnimations = true
        }
    }

    private func clockButton(at date: Date) -> some View {
        let language = languageStore.language
        let cycle = HomeClockCycle(localTimeZone: .autoupdatingCurrent,
                                   deadlineTimeZone: deadlineTimeZone, startTimeZone: startTimeZone,
                                   referenceDate: date)
        let mode = cycle.resolvedMode(preferredMode)
        let zone = cycle.timeZone(for: mode)
        let dateText = zone.map { UntiliaDateFormatting.dateString(date, timeZone: $0, abbreviatedMonth: true, language: language) } ?? ""
        let timeText = zone.map { UntiliaDateFormatting.timeString(date, timeZone: $0, language: language, includingSeconds: true) } ?? ""
        let zoneText = zone.map { UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: $0, at: date) } ?? ""

        return Button {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) { storedMode = cycle.next(after: preferredMode).rawValue }
        } label: {
            ZStack(alignment: .leading) {
                // Reserve the full clock width in every mode, including hidden.
                // Hidden labels measure the available zones but never draw or tick.
                ForEach(cycle.modes.filter { $0 != .hidden }, id: \.rawValue) { referenceMode in
                    if let referenceZone = cycle.timeZone(for: referenceMode) {
                        clockLabel(
                            date: UntiliaDateFormatting.dateString(date, timeZone: referenceZone, abbreviatedMonth: true, language: language),
                            time: UntiliaDateFormatting.timeString(date, timeZone: referenceZone, language: language, includingSeconds: true),
                            zone: UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: referenceZone, at: date),
                            language: language
                        )
                        .hidden()
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                    }
                }
                if mode == .hidden {
                    Circle()
                        .fill(theme.accent.opacity(0.85))
                        .frame(width: 6, height: 6)
                        .transition(.identity)
                } else {
                    clockLabel(date: dateText, time: timeText, zone: zoneText, language: language)
                        .transition(.identity)
                }
            }
            .frame(minWidth: 44, minHeight: 52, alignment: .leading)
            .padding(.leading, leadingInset)
            .contentShape(Rectangle())
        }
        .buttonStyle(InstantClockButtonStyle())
        .accessibilityLabel(mode == .hidden
            ? L10n.text(.clockHidden, language: language)
            : "\(dateText), \(timeText), \(zoneText)")
        .accessibilityValue(L10n.text(accessibilityKey(for: mode), language: language))
        .accessibilityHint(L10n.text(.cycleClock, language: language))
        .accessibilityIdentifier("localClock")
    }

    private func accessibilityKey(for mode: HomeClockMode) -> L10n.Key {
        switch mode {
        case .local: .clockLocal
        case .deadline: .clockDeadline
        case .start: .clockStart
        case .hidden: .clockHidden
        }
    }

    private func clockLabel(date: String, time: String, zone: String, language: AppLanguage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date.uppercased(with: language.locale))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(.white.opacity(0.62))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(time)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.94))
                Text("·")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
                    .frame(width: 4)
                Text(zone)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.accent.opacity(0.94))
            }
            .lineLimit(1)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.22), radius: 6, y: 2)
        .contentTransition(.identity)
    }
}

/// Unlike the standard plain style, pressing the clock never dims its label.
private struct InstantClockButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
