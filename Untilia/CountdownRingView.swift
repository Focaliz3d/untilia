//
//  CountdownRingView.swift
//  Untilia
//

import SwiftUI
import UIKit

enum CountdownDisplayMode: Int, CaseIterable, Equatable {
    case years
    case months
    case weeks
    case days
    case hours
    case minutes
    case seconds

    var localizedUnit: L10n.Unit {
        switch self {
        case .years: .years
        case .months: .months
        case .weeks: .weeks
        case .days: .days
        case .hours: .hours
        case .minutes: .minutes
        case .seconds: .seconds
        }
    }
}

func remainingSecondsTotal(for snapshot: CountdownSnapshot) -> Int {
    snapshot.remainingHours * 3_600
        + snapshot.remainingMinutes * 60
        + snapshot.remainingSeconds
}

func availableCountdownDisplayModes(for snapshot: CountdownSnapshot) -> [CountdownDisplayMode] {
    let totalSeconds = remainingSecondsTotal(for: snapshot)
    let totalMonths = snapshot.yearsRemaining * 12 + snapshot.monthsAfterYearsRemaining
    let totalWeeks = totalSeconds / 604_800
    let totalDays = totalSeconds / 86_400
    let totalHours = totalSeconds / 3_600
    let totalMinutes = totalSeconds / 60
    let includesSeconds = totalSeconds > 0 || snapshot.isElapsed

    return [
        snapshot.yearsRemaining > 0 ? .years : nil,
        totalMonths > 0 ? .months : nil,
        totalWeeks > 0 ? .weeks : nil,
        totalDays > 0 ? .days : nil,
        totalHours > 0 ? .hours : nil,
        totalMinutes > 0 ? .minutes : nil,
        includesSeconds ? .seconds : nil
    ].compactMap { $0 }
}

func lowerAvailableMode(
    than mode: CountdownDisplayMode,
    in availableModes: [CountdownDisplayMode]
) -> CountdownDisplayMode? {
    availableModes.first(where: { $0.rawValue > mode.rawValue })
}

func resolvedCountdownDisplayMode(rawValue: Int, availableModes: [CountdownDisplayMode]) -> CountdownDisplayMode? {
    guard let preferred = CountdownDisplayMode(rawValue: rawValue) else { return availableModes.first }
    if availableModes.contains(preferred) { return preferred }
    return lowerAvailableMode(than: preferred, in: availableModes) ?? availableModes.last
}

struct CountdownRing: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    let snapshot: CountdownSnapshot
    let targetDate: Date
    let targetTimeZone: TimeZone
    let persistedDisplayModeRawValue: Int
    let theme: UntiliaTheme
    let onDisplayModeChanged: (Int) -> Void
    @State private var displayModeFeedbackGenerator: UIImpactFeedbackGenerator?

    private var ringProgress: CGFloat {
        min(max(snapshot.progress, 0), 1)
    }

    private var language: AppLanguage { languageStore.language }

    private var availableDisplayModes: [CountdownDisplayMode] {
        availableCountdownDisplayModes(for: snapshot)
    }

    private var activeDisplayMode: CountdownDisplayMode? {
        resolvedCountdownDisplayMode(rawValue: persistedDisplayModeRawValue, availableModes: availableDisplayModes)
    }

    private var targetTimeZoneText: String {
        UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: targetTimeZone, at: targetDate)
    }

    var body: some View {
        GeometryReader { geometry in
            let ringContentWidth = max(geometry.size.width - 68, 128)
            let countdownContentHeight = min(max(geometry.size.width * 0.32, 72), 100)
            let verticalInset = min(max(geometry.size.width * 0.095, 22), 36)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.accent.opacity(0.22), .clear],
                            center: .center,
                            startRadius: 12,
                            endRadius: geometry.size.width * 0.56
                        )
                    )
                    .blur(radius: 8)

                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 12)
                    .padding(28)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        AngularGradient(colors: theme.ringColors, center: .center),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(28)
                    .shadow(color: theme.ringColors[0].opacity(0.32), radius: 13)
                    .shadow(color: theme.ringColors[2].opacity(0.24), radius: 22)

                if !snapshot.isReached {
                    ringMarker(in: geometry.size)
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    Text(
                        snapshot.isElapsed
                            ? L10n.text(.timeElapsed, language: language)
                            : snapshot.isReached ? L10n.text(.dateReached, language: language) : L10n.text(.timeLeft, language: language)
                    )
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.66))
                        .offset(y: 8)

                    Spacer(minLength: 0)

                    if let activeDisplayMode {
                        AdaptiveRemainingTime(
                            snapshot: snapshot,
                            displayMode: activeDisplayMode,
                            availableWidth: ringContentWidth,
                            language: language
                        )
                            .offset(y: 10)
                            .frame(height: countdownContentHeight)
                    } else {
                        Text(L10n.text(.now, language: language))
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(.white)
                            .offset(y: 10)
                            .frame(height: 100)
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 5) {
                        Text((snapshot.isElapsed ? L10n.text(.since, language: language) : L10n.text(.until, language: language)).uppercased(with: language.locale))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.58))

                        VStack(spacing: 2) {
                            Text(UntiliaDateFormatting.dateString(targetDate, timeZone: targetTimeZone, abbreviatedMonth: true, language: language))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))

                            HStack(alignment: .firstTextBaseline, spacing: 5) {
                                Text(UntiliaDateFormatting.timeString(targetDate, timeZone: targetTimeZone, language: language))
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                                Text("·")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.48))

                                Text(targetTimeZoneText)
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(theme.accent.opacity(0.84))
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(theme.accent.opacity(0.9))
                        }
                        .foregroundStyle(.white.opacity(0.96))
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, verticalInset)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Circle())
        .onTapGesture {
            guard let activeDisplayMode,
                  let currentIndex = availableDisplayModes.firstIndex(of: activeDisplayMode)
            else { return }
            let nextDisplayMode = availableDisplayModes[(currentIndex + 1) % availableDisplayModes.count]
            onDisplayModeChanged(nextDisplayMode.rawValue)
            if displayModeFeedbackGenerator == nil {
                displayModeFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            }
            displayModeFeedbackGenerator?.impactOccurred(intensity: 1)
        }
        .onChange(of: availableDisplayModes) { _, availableModes in
            guard let preferred = CountdownDisplayMode(rawValue: persistedDisplayModeRawValue),
                  !availableModes.contains(preferred)
            else { return }
            if let fallbackDisplayMode = resolvedCountdownDisplayMode(rawValue: persistedDisplayModeRawValue, availableModes: availableModes) {
                onDisplayModeChanged(fallbackDisplayMode.rawValue)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.countdownAccessibility(snapshot: snapshot, language: language))
        .accessibilityValue(activeDisplayMode.map { L10n.unitName(2, $0.localizedUnit, language: language) } ?? L10n.text(.now, language: language))
        .accessibilityIdentifier("daysRemaining")
    }

    private func ringMarker(in size: CGSize) -> some View {
        let angle = (ringProgress * 2 * .pi) - (.pi / 2)
        let radius = max((size.width / 2) - 28, 0)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let markerPosition = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )

        return ZStack {
            Circle()
                .fill(theme.accent.opacity(0.5))
                .frame(width: 34, height: 34)
                .blur(radius: 8)

            Circle()
                .fill(.white)
                .frame(width: 13, height: 13)
                .shadow(color: .white.opacity(0.9), radius: 7)
                .shadow(color: theme.accent.opacity(0.7), radius: 14)
        }
        .position(markerPosition)
        .accessibilityHidden(true)
    }
}

private struct AdaptiveRemainingTime: View {
    let snapshot: CountdownSnapshot
    let displayMode: CountdownDisplayMode
    let availableWidth: CGFloat
    let language: AppLanguage

    private var primaryWidth: CGFloat { min(max(availableWidth, 128), 270) }
    private var primaryNumberSize: CGFloat { min(max(primaryWidth * 0.18, 26), 40) }
    private var primaryUnitSize: CGFloat { min(max(primaryWidth * 0.07, 12), 16) }
    private var secondaryTextSize: CGFloat { min(max(primaryWidth * 0.06, 12), 15) }
    private var totalRemainingSeconds: Int { remainingSecondsTotal(for: snapshot) }
    private var totalMonths: Int { snapshot.yearsRemaining * 12 + snapshot.monthsAfterYearsRemaining }
    private var totalWeeks: Int { totalRemainingSeconds / 604_800 }
    private var totalDays: Int { totalRemainingSeconds / 86_400 }
    private var totalHours: Int { totalRemainingSeconds / 3_600 }
    private var totalMinutes: Int { totalRemainingSeconds / 60 }

    private var primaryDisplay: (value: Int, unit: String) {
        switch displayMode {
        case .years: (snapshot.yearsRemaining, L10n.unitName(snapshot.yearsRemaining, .years, language: language, uppercase: true))
        case .months: (totalMonths, L10n.unitName(totalMonths, .months, language: language, uppercase: true))
        case .weeks: (totalWeeks, L10n.unitName(totalWeeks, .weeks, language: language, uppercase: true))
        case .days: (totalDays, L10n.unitName(totalDays, .days, language: language, uppercase: true))
        case .hours: (totalHours, L10n.unitName(totalHours, .hours, language: language, uppercase: true))
        case .minutes: (totalMinutes, L10n.unitName(totalMinutes, .minutes, language: language, uppercase: true))
        case .seconds: (totalRemainingSeconds, L10n.unitName(totalRemainingSeconds, .seconds, language: language, uppercase: true))
        }
    }

    private var secondaryLines: [String] {
        CountdownSecondaryFormatting.lines(for: snapshot, mode: displayMode, language: language)
    }

    private var primaryLine: some View {
        let primary = primaryDisplay
        let number = Text(verbatim: String(primary.value)).font(.system(size: primaryNumberSize, weight: .semibold, design: .rounded)).monospacedDigit()
        let unit = Text(primary.unit).font(.system(size: primaryUnitSize, weight: .semibold, design: .rounded)).tracking(0.4)
        return ViewThatFits(in: .horizontal) {
            Text("\(number) \(unit)").fixedSize(horizontal: true, vertical: false)
            VStack(spacing: 0) {
                number.lineLimit(1).minimumScaleFactor(0.55).frame(width: primaryWidth)
                unit
            }
        }
        .contentTransition(.numericText())
        .frame(width: primaryWidth)
    }

    var body: some View {
        VStack(spacing: 3) {
            primaryLine
            ForEach(secondaryLines, id: \.self) { line in
                Text(line)
                    .font(.system(size: secondaryTextSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.60)
                    .frame(width: primaryWidth)
            }
        }
        .foregroundStyle(.white)
        .minimumScaleFactor(0.55)
        .lineLimit(1)
        .frame(height: secondaryLines.isEmpty ? 72 : 100, alignment: .center)
    }

}
