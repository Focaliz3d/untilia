//
//  ContentView.swift
//  Untilia
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = UntiliaStore()
    @StateObject private var languageStore = AppLanguageStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingSettings = false
    @State private var isShowingAbout = false
    @State private var previewTargetIndex: Int?

    var body: some View {
        GeometryReader { viewport in
            let insets = viewport.safeAreaInsets
            GeometryReader { screen in
                let pageSize = screen.size
                let contentSize = CGSize(width: viewport.size.width, height: pageSize.height - insets.bottom)
                ZStack(alignment: .top) {
                    CountdownPager(
                        selectedIndex: Binding(
                            get: { store.selectedTargetIndex },
                            set: { store.selectTarget(at: $0) }
                        ),
                        pageCount: store.targetDates.count,
                        onVisibleIndexChanged: { previewTargetIndex = $0 }
                    ) { index, isLive in
                        // Les pages voisines restent disponibles pour le geste natif,
                        // sans faire tourner trois décomptes chaque seconde.
                        TimelineView(
                            CountdownTimelineSchedule(
                                isPaused: !isLive || isShowingSettings || isShowingAbout || scenePhase != .active
                            )
                        ) { context in
                            homePage(
                                at: index, now: context.date, layer: .page,
                                layoutSize: contentSize, safeAreaInsets: insets,
                                pageSize: pageSize
                            )
                        }
                        .environmentObject(languageStore)
                        .environment(\.locale, languageStore.language.locale)
                        .environment(\.colorScheme, .dark)
                    }

                    homePage(
                        at: previewTargetIndex ?? store.selectedTargetIndex, now: Date(), layer: .controls,
                        layoutSize: contentSize, safeAreaInsets: insets, pageSize: pageSize
                    )

                    if isShowingSettings && pageSize.width > pageSize.height {
                        // Cover the home screen behind the landscape sheet,
                        // without changing the sheet's bounds or editor layout.
                        Color.untiliaInk
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                            .transition(.identity)
                    }
                }
            }
            .ignoresSafeArea()
        }
        .background(Color.untiliaInk.ignoresSafeArea())
        .environmentObject(store)
        .environmentObject(languageStore)
        .environment(\.locale, languageStore.language.locale)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            store.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            store.refresh()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(store: store)
                .environmentObject(store)
                .environmentObject(languageStore)
        }
        .sheet(isPresented: $isShowingAbout) {
            AboutView(theme: UntiliaTheme(rawValue: store.selectedTargetIndex) ?? .twilight)
                .environmentObject(languageStore)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("untiliaHome")
    }

    private func homePage(
        at index: Int, now: Date, layer: UntiliaHomeLayer,
        layoutSize: CGSize, safeAreaInsets: EdgeInsets, pageSize: CGSize
    ) -> some View {
        UntiliaHomeView(
            layer: layer,
            isClockPaused: isShowingSettings || isShowingAbout || scenePhase != .active,
            layoutSize: layoutSize,
            safeAreaInsets: safeAreaInsets,
            pageSize: pageSize,
            targetDates: store.targetDates,
            targetNames: store.targetNames,
            targetTimeZoneIdentifiers: store.targetTimeZoneIdentifiers,
            countdownStartDates: store.countdownStartDates,
            countdownStartTimeZoneIdentifiers: store.countdownStartTimeZoneIdentifiers,
            countdownDisplayModeRawValues: store.countdownDisplayModeRawValues,
            selectedTargetIndex: index,
            now: now,
            onSelectTarget: { selectedIndex in
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    previewTargetIndex = nil
                    store.selectTarget(at: selectedIndex)
                }
            },
            onSelectDisplayMode: { store.updateCountdownDisplayMode(rawValue: $0, for: index) },
            onSettings: { isShowingSettings = true },
            onAbout: { isShowingAbout = true }
        )
    }
}

private enum UntiliaHomeLayer {
    case page
    case controls
}

/// Un fond unique par page, dimensionné sur toute la surface de l'écran.
private struct UntiliaBackdrop: View {
    let theme: UntiliaTheme
    let canvasSize: CGSize

    var body: some View {
        ZStack {
            Color.untiliaInk
            Image(theme.imageName)
                .resizable()
                .scaledToFill()
                .scaleEffect(1.12)
                .offset(y: -canvasSize.height * 0.06)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
            LinearGradient(
                colors: [
                    theme.backgroundGradient[0].opacity(0.72),
                    theme.backgroundGradient[0].opacity(0.38),
                    .clear,
                    theme.backgroundGradient[1].opacity(0.30),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct UntiliaHomeView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    let layer: UntiliaHomeLayer
    let isClockPaused: Bool
    let layoutSize: CGSize
    let safeAreaInsets: EdgeInsets
    let pageSize: CGSize
    let targetDates: [Date]
    let targetNames: [String]
    let targetTimeZoneIdentifiers: [String]
    let countdownStartDates: [Date]
    let countdownStartTimeZoneIdentifiers: [String]
    let countdownDisplayModeRawValues: [Int]
    let selectedTargetIndex: Int
    let now: Date
    let onSelectTarget: (Int) -> Void
    let onSelectDisplayMode: (Int) -> Void
    let onSettings: () -> Void
    let onAbout: () -> Void

    private var language: AppLanguage { languageStore.language }

    private var selectedTargetDate: Date {
        targetDates[safe: selectedTargetIndex] ?? targetDates[0]
    }

    private var selectedStartDate: Date {
        countdownStartDates[safe: selectedTargetIndex] ?? countdownStartDates[0]
    }

    private var selectedTargetTimeZone: TimeZone {
        TimeZone(identifier: targetTimeZoneIdentifiers[safe: selectedTargetIndex] ?? "") ?? .autoupdatingCurrent
    }

    private var selectedStartTimeZone: TimeZone {
        TimeZone(identifier: countdownStartTimeZoneIdentifiers[safe: selectedTargetIndex] ?? "") ?? selectedTargetTimeZone
    }

    private var selectedDisplayModeRawValue: Int {
        countdownDisplayModeRawValues[safe: selectedTargetIndex] ?? CountdownDisplayMode.years.rawValue
    }

    private var selectedTargetCalendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = selectedTargetTimeZone
        return calendar
    }

    private var selectedTheme: UntiliaTheme {
        UntiliaTheme(rawValue: selectedTargetIndex) ?? .twilight
    }

    private var countdownSnapshot: CountdownSnapshot {
        CountdownEngine.snapshot(
            now: now,
            target: selectedTargetDate,
            startDate: selectedStartDate,
            calendar: selectedTargetCalendar
        )
    }

    var body: some View {
        GeometryReader { _ in
            let horizontalPadding = min(max(layoutSize.width * 0.055, 18), 26)
            let ringSize = min(layoutSize.width - 36, min(layoutSize.height * 0.43, 382))
            let targetCardHeight = min(max(layoutSize.height * 0.16, 112), 144)
            let progressCardPadding = min(max(layoutSize.height * 0.025, 16), 24)
            let sectionSpacing = min(max(layoutSize.height * 0.024, 16), 30)
            let ringToCardsSpacing = min(max(layoutSize.height * 0.06, 24), 60)
            let ringTopPadding = min(max(layoutSize.height * 0.025, 12), 26)
            let contentDownshift = min(max(layoutSize.height * 0.028, 18), 28)
            let isLandscape = layoutSize.width > layoutSize.height
            let snapshot = countdownSnapshot

            ZStack(alignment: .top) {
                if layer == .page {
                    UntiliaBackdrop(theme: selectedTheme, canvasSize: pageSize)
                }

                if isLandscape {
                    landscapeHomeContent(
                        width: layoutSize.width,
                        height: layoutSize.height,
                        safeAreaTop: safeAreaInsets.top,
                        safeAreaBottom: safeAreaInsets.bottom,
                        snapshot: snapshot
                    )
                } else {
                    VStack(spacing: 0) {
                        topBar(theme: selectedTheme)
                            .padding(.top, safeAreaInsets.top + 20)

                        countdownRing(width: ringSize, snapshot: snapshot)
                            .padding(.top, ringTopPadding + contentDownshift)

                        Spacer(minLength: ringToCardsSpacing)

                        targetCards(height: targetCardHeight)
                            .padding(.horizontal, horizontalPadding)

                        progressCard(verticalPadding: progressCardPadding, snapshot: snapshot)
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, sectionSpacing)
                    }
                    .frame(minHeight: layoutSize.height)
                    .padding(.bottom, 10)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: pageSize.width, height: pageSize.height, alignment: .top)
        }
    }

    private func landscapeHomeContent(
        width: CGFloat,
        height: CGFloat,
        safeAreaTop: CGFloat,
        safeAreaBottom: CGFloat,
        snapshot: CountdownSnapshot
    ) -> some View {
        let horizontalPadding = min(max(width * 0.035, 20), 44)
        let ringSize = min(max(height * 0.86, 265), 340)
        let targetCardHeight = min(max(height * 0.18, 58), 72)
        let progressCardPadding = min(max(height * 0.02, 8), 12)
        let sidebarWidth = min(max(width * 0.36, 260), 340)
        let targetCardsHeight = targetCardHeight * 3 + 16
        let progressCardHeight = min(max(height * 0.22, 80), 94)
        let sidebarHeight = targetCardsHeight + progressCardHeight + 10
        let topBarPadding = min(max(width * 0.055, 34), 52)

        return VStack(spacing: 8) {
            topBar(theme: selectedTheme, horizontalPadding: topBarPadding, showsHelp: false)
                .padding(.top, safeAreaTop + 14)

            HStack(spacing: min(max(width * 0.03, 16), 28)) {
                countdownRing(width: ringSize, snapshot: snapshot)

                VStack(spacing: 10) {
                    targetCards(height: targetCardHeight, isVertical: true)
                        .frame(height: targetCardsHeight, alignment: .top)

                    progressCard(verticalPadding: progressCardPadding, isCompact: true, snapshot: snapshot)
                        .frame(height: progressCardHeight)
                }
                .frame(width: sidebarWidth, height: sidebarHeight)
            }
            .padding(.horizontal, horizontalPadding)
            .offset(y: -7)
            .frame(maxHeight: .infinity)
        }
        .padding(.bottom, safeAreaBottom + 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            if layer == .controls {
                helpButton(theme: selectedTheme)
                    .padding(.trailing, topBarPadding)
                    .padding(.top, safeAreaTop + 14 + 52 + 8)
            }
        }
    }

    @ViewBuilder
    private func countdownRing(width: CGFloat, snapshot: CountdownSnapshot) -> some View {
        if layer == .controls {
            Color.clear.frame(width: width, height: width)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            CountdownRing(
                snapshot: snapshot,
                targetDate: selectedTargetDate,
                targetTimeZone: selectedTargetTimeZone,
                persistedDisplayModeRawValue: selectedDisplayModeRawValue,
                theme: selectedTheme,
                onDisplayModeChanged: onSelectDisplayMode
            )
            .id(selectedTargetIndex)
            .frame(width: width)
        }
    }

    @ViewBuilder
    private func targetCards(height: CGFloat, isVertical: Bool = false) -> some View {
        if layer == .page {
            Color.clear.frame(height: isVertical ? height * 3 + 16 : height)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            TargetDateCards(
                dates: targetDates,
                names: targetNames,
                timeZoneIdentifiers: targetTimeZoneIdentifiers,
                selectedIndex: selectedTargetIndex,
                cardHeight: height,
                isVertical: isVertical,
                language: language,
                onSelect: onSelectTarget
            )
        }
    }

    private func progressCard(
        verticalPadding: CGFloat,
        isCompact: Bool = false,
        snapshot: CountdownSnapshot
    ) -> some View {
        let card = CountdownProgressCard(
            progress: snapshot.progress,
            startDate: selectedStartDate,
            startTimeZone: selectedStartTimeZone,
            targetDate: selectedTargetDate,
            targetTimeZone: selectedTargetTimeZone,
            isElapsed: snapshot.isElapsed,
            isCompact: isCompact,
            theme: selectedTheme,
            verticalPadding: verticalPadding,
            language: language
        )
        return Group {
            if layer == .page {
                card
            } else {
                // Keep its intrinsic layout without drawing a second status card.
                card.hidden().allowsHitTesting(false).accessibilityHidden(true)
            }
        }
    }

    private func helpButton(theme: UntiliaTheme) -> some View {
        Button(action: onAbout) {
            Image(systemName: "questionmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 52, height: 52)
                .background(theme.accent.opacity(0.18), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
                .compositingGroup()
                .shadow(color: theme.accent.opacity(0.18), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(.about, language: language))
        .accessibilityIdentifier("aboutButton")
    }

    @ViewBuilder
    private func topBar(theme: UntiliaTheme, horizontalPadding: CGFloat = 24, showsHelp: Bool = true) -> some View {
        if layer == .page {
            Color.clear.frame(height: 52)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            HStack(alignment: .center, spacing: 8) {
                HomeClockView(theme: theme, deadlineTimeZone: selectedTargetTimeZone,
                              startTimeZone: selectedStartTimeZone, isPaused: isClockPaused,
                              leadingInset: horizontalPadding)

                Spacer()

                if showsHelp {
                    helpButton(theme: theme)
                }

                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: 52, height: 52)
                        .background(theme.accent.opacity(0.18), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
                        .compositingGroup()
                        .shadow(color: theme.accent.opacity(0.18), radius: 14, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text(.settings, language: language))
                .accessibilityIdentifier("settingsButton")
            }
            // The clock owns the leading inset so its touch area reaches the edge.
            .padding(.trailing, horizontalPadding)
        }
    }

}

#Preview {
    ContentView()
}
