//
//  UntiliaUITests.swift
//  UntiliaUITests
//
//  Created by Olivier on 20/10/2026.
//

import XCTest

final class UntiliaUITests: XCTestCase {

    @MainActor
    func testLandscapeSettingsLongTimeZonesStayInsideCenteredFields() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-daysLeft.targetTimeZones", "(\"Europe/Paris\", \"Australia/Adelaide\", \"Europe/Paris\")",
            "-daysLeft.countdownStartTimeZones", "(\"Europe/Paris\", \"Asia/Karachi\", \"Europe/Paris\")"
        ]
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["closeSettingsButton"].waitForExistence(timeout: 5))
        app.buttons["settingsDateSelector1"].tap()
        let nameBefore = app.buttons["nameEditorButton"].frame
        let cardsBefore = app.buttons["settingsDateSelector1"].frame
        let saveBefore = app.buttons["validateDateButton"].frame
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Landscape forest — full UTC offsets and balanced fields"
        shot.lifetime = .keepAlways
        add(shot)
        let name = app.buttons["nameEditorButton"].frame
        let deadline = app.buttons["targetDateSummaryButton"].frame
        let cards = app.buttons["settingsDateSelector1"].frame
        let save = app.buttons["validateDateButton"].frame
        XCTAssertEqual(name.midY, nameBefore.midY, accuracy: 1)
        XCTAssertEqual(cards.midY, cardsBefore.midY, accuracy: 1)
        XCTAssertEqual(save.midY, saveBefore.midY, accuracy: 1)
        XCTAssertEqual(name.minY - cards.maxY, save.minY - deadline.maxY, accuracy: 2)
        for field in ["startDateSummaryButton", "targetDateSummaryButton"] {
            let row = app.buttons[field]
            XCTAssertLessThanOrEqual(row.frame.maxX, app.buttons["settingsDateSelector2"].frame.maxX + 1)
            XCTAssertGreaterThanOrEqual(row.frame.minX, app.buttons["settingsDateSelector0"].frame.minX - 1)
            XCTAssertTrue(row.label.contains("UTC+"))
        }
    }

    @MainActor
    func testPortraitSettingsDetailsHaveBalancedOpticalSpacing() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["closeSettingsButton"].waitForExistence(timeout: 5))
        for index in [0, 2] {
            app.buttons["settingsDateSelector\(index)"].tap()
            let cardsBottom = (0..<3).map { app.buttons["settingsDateSelector\($0)"].frame.maxY }.max()!
            let name = app.buttons["nameEditorButton"].frame
            let deadline = app.buttons["targetDateSummaryButton"].frame
            let month = app.buttons.matching(NSPredicate(format: "label IN %@", ["Choose month and year", "Choisir le mois et l’année"])).firstMatch.frame
            let topGap = name.minY - cardsBottom
            let bottomGap = month.minY - 10 - deadline.maxY
            XCTAssertGreaterThan(topGap, 12)
            XCTAssertGreaterThan(bottomGap, 12)
            // A small extra geometric gap above compensates for the shadow.
            XCTAssertGreaterThan(topGap, bottomGap)
            XCTAssertLessThan(topGap - bottomGap, 8)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Portrait settings optical spacing — \(index)"
            shot.lifetime = .keepAlways
            add(shot)
        }
    }

    @MainActor
    func testCountdownSecondaryUnitsLayoutInBothOrientations() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        app.buttons["targetDateCard0"].tap()
        let ring = app.descendants(matching: .any).matching(identifier: "daysRemaining").firstMatch
        XCTAssertTrue(ring.waitForExistence(timeout: 5))
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            var seen = Set<String>()
            for _ in 0..<7 {
                let mode = ring.value as? String ?? ""
                XCTAssertFalse(mode.isEmpty)
                if seen.contains(mode) { break }
                seen.insert(mode)
                XCTAssertTrue(ring.isHittable)
                let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                screenshot.name = "Full secondary units — \(mode) — \(orientation.rawValue)"
                screenshot.lifetime = .keepAlways
                add(screenshot)
                ring.tap()
            }
            XCTAssertGreaterThanOrEqual(seen.count, 4)
        }
    }

    @MainActor
    func testSettingsLandscapeLayoutFitsSheetBounds() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["closeSettingsButton"].waitForExistence(timeout: 5))
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "Settings landscape sheet bounds"
        attachment.lifetime = .keepAlways
        add(attachment)
        for day in [15, 16, 30, 31] {
            XCTAssertTrue(app.buttons["calendarDay\(day)"].isHittable)
        }
        XCTAssertLessThanOrEqual(app.buttons["validateDateButton"].frame.maxY, app.windows.firstMatch.frame.maxY - 20)
        app.buttons["settingsHelpButton"].tap()
        XCTAssertTrue(app.buttons["closeAboutButton"].waitForExistence(timeout: 5))
        app.buttons["closeAboutButton"].tap()
        let handle = app.buttons["closeSettingsButton"]
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 270)))
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: handle)
        let result = XCTWaiter.wait(for: [closed], timeout: 5)
        XCTAssertEqual(result, .completed)
    }

    @MainActor
    func testSettingsSheetHandleDismissesAndProtectsUnsavedChanges() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        app.buttons["targetDateCard0"].tap()
        app.buttons["settingsButton"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["English"].tap()
        app.buttons["closeSettingsButton"].tap()

        func dragHandle() {
            let handle = app.buttons["closeSettingsButton"]
            let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let distance = app.windows.firstMatch.frame.height * 0.7
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: distance)))
        }
        func assertClosed() {
            let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.buttons["closeSettingsButton"])
            XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 5), .completed)
        }
        assertClosed()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            app.buttons["settingsButton"].tap()
            let handle = app.buttons["closeSettingsButton"]
            XCTAssertTrue(handle.waitForExistence(timeout: 5))
            XCTAssertTrue(handle.isHittable)
            XCTAssertGreaterThanOrEqual(handle.frame.height, 44)
            XCTAssertEqual(handle.label, "Close")
            XCTAssertTrue(app.buttons["calendarDay15"].isHittable)
            XCTAssertTrue(app.buttons["calendarDay16"].isHittable)
            XCTAssertTrue(app.buttons["languageButton"].isHittable)
            let save = app.buttons["validateDateButton"]
            XCTAssertLessThanOrEqual(save.frame.maxY, app.windows.firstMatch.frame.maxY - 20)
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Settings sheet — \(orientation.rawValue)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            // Nested Help must close back into Settings, not dismiss its parent.
            app.buttons["settingsHelpButton"].tap()
            XCTAssertTrue(app.buttons["closeAboutButton"].waitForExistence(timeout: 5))
            app.buttons["closeAboutButton"].tap()
            XCTAssertTrue(handle.waitForExistence(timeout: 5))
            let original = app.buttons["targetDateSummaryButton"].label
            dragHandle()
            assertClosed()

            app.buttons["settingsButton"].tap()
            XCTAssertTrue(handle.waitForExistence(timeout: 5))
            app.buttons["calendarDay15"].tap()
            app.buttons["calendarDay16"].tap()
            let edited = app.buttons["targetDateSummaryButton"].label
            XCTAssertNotEqual(edited, original)
            dragHandle()
            XCTAssertTrue(app.alerts["Unsaved changes"].waitForExistence(timeout: 5))
            app.buttons["Stay in Settings"].tap()
            XCTAssertEqual(app.buttons["targetDateSummaryButton"].label, edited)
            XCTAssertTrue(save.isEnabled)
            dragHandle()
            XCTAssertTrue(app.alerts["Unsaved changes"].waitForExistence(timeout: 5))
            app.buttons["Leave without saving"].tap()
            assertClosed()
            app.buttons["settingsButton"].tap()
            XCTAssertTrue(handle.waitForExistence(timeout: 5))
            XCTAssertEqual(app.buttons["targetDateSummaryButton"].label, original)
            XCTAssertFalse(save.isEnabled)
            dragHandle()
            assertClosed()
        }
        // Restore the language before rotating; a rotation still in flight can
        // otherwise move the gear underneath XCTest's synthesized touch.
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["closeSettingsButton"].waitForExistence(timeout: 5))
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
        app.buttons["closeSettingsButton"].tap()
        assertClosed()
    }

    @MainActor
    func testHelpHeaderScrollsWithContentWhileDismissHandleStaysFixed() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            app.buttons["aboutButton"].tap()
            let handle = app.buttons["closeAboutButton"]
            XCTAssertTrue(handle.waitForExistence(timeout: 5))
            let title = app.staticTexts["Untilia"]
            let globe = app.buttons["helpLanguageButton"]
            let version = app.staticTexts["appVersionLabel"]
            XCTAssertTrue(title.isHittable)
            XCTAssertTrue(globe.isHittable)
            XCTAssertTrue(version.isHittable)
            let initialHandle = handle.frame
            let initialTitle = title.frame
            let initialGlobe = globe.frame
            let scroll = app.scrollViews["helpScrollView"]
            // A short drag proves that title and globe move together, not just
            // that a different section can be reached further down the guide.
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.7))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -90)), withVelocity: .slow, thenHoldForDuration: 0.2)
            XCTAssertEqual(handle.frame.minY, initialHandle.minY, accuracy: 1)
            if title.isHittable {
                XCTAssertLessThan(title.frame.minY, initialTitle.minY - 10)
                XCTAssertLessThan(globe.frame.minY, initialGlobe.minY - 10)
            }
            for _ in 0..<3 { scroll.swipeUp() }
            XCTAssertFalse(title.isHittable)
            XCTAssertFalse(globe.isHittable)
            XCTAssertFalse(version.isHittable)
            XCTAssertTrue(handle.isHittable)
            XCTAssertEqual(handle.frame.minY, initialHandle.minY, accuracy: 1)
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Help header scrolled away — \(orientation.rawValue)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            handle.tap()
            let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: handle)
            XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
        }
    }

    @MainActor
    func testCountdownUnitsStayIndependentWhenPagingAndWrapping() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        app.buttons["settingsButton"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["English"].tap()
        app.buttons["closeSettingsButton"].tap()
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.buttons["closeSettingsButton"])
        XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 5), .completed)
        let expected = ["SECONDS", "MINUTES", "HOURS"]
        let ring = app.descendants(matching: .any).matching(identifier: "daysRemaining").firstMatch
        for (index, unit) in expected.enumerated() {
            app.buttons["targetDateCard\(index)"].tap()
            XCTAssertTrue(ring.waitForExistence(timeout: 5))
            for _ in 0..<7 {
                if ring.value as? String == unit { break }
                ring.tap()
            }
            XCTAssertEqual(ring.value as? String, unit)
        }
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            app.buttons["targetDateCard0"].tap()
            for (index, left) in [(1, true), (0, false), (2, false), (0, true), (1, true), (2, true), (0, true)] {
                if left { app.swipeLeft() } else { app.swipeRight() }
                XCTAssertTrue(app.buttons["targetDateCard\(index)"].isSelected)
                XCTAssertEqual(ring.value as? String, expected[index])
            }
        }
        app.terminate()
        app.launch()
        for index in [0, 1, 2] {
            app.buttons["targetDateCard\(index)"].tap()
            XCTAssertEqual(ring.value as? String, expected[index])
        }
        XCUIDevice.shared.orientation = .portrait
        app.buttons["settingsButton"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
    }

    @MainActor
    func testMonthYearWheelsRemainInteractiveOnRepeatedPresentations() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        app.buttons["settingsButton"].tap()
        app.buttons["settingsDateSelector0"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["English"].tap()
        let summary = app.buttons["targetDateSummaryButton"]

        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            for year in ["2500", "1900", "2028"] {
                app.buttons["Choose month and year"].tap()
                let wheels = app.pickerWheels
                XCTAssertTrue(wheels.element(boundBy: 0).waitForExistence(timeout: 3))
                XCTAssertEqual(wheels.count, 2)
                wheels.element(boundBy: 1).adjust(toPickerWheelValue: year)
                wheels.element(boundBy: 0).adjust(toPickerWheelValue: "February")
                XCTAssertEqual(wheels.element(boundBy: 1).value as? String, year)
                XCTAssertEqual(wheels.element(boundBy: 0).value as? String, "February")
                let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                screenshot.name = "Month and year — \(year) — \(orientation.rawValue)"
                screenshot.lifetime = .keepAlways
                add(screenshot)
                let start = wheels.element(boundBy: 0).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
                    .withOffset(CGVector(dx: 0, dy: -18))
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 350)))
                let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: wheels.element(boundBy: 0))
                XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 5), .completed)
                XCTAssertTrue(summary.label.contains(year))
                XCTAssertTrue(summary.label.contains("Feb"))
            }
        }
        XCUIDevice.shared.orientation = .portrait
        // No save: navigating back keeps the existing discard-confirmation flow.
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
    }

    @MainActor
    func testMonthYearSelectionClampsDaysWithoutChangingTimeOrZone() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        app.buttons["settingsButton"].tap()
        app.buttons["settingsDateSelector0"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["English"].tap()
        let summary = app.buttons["targetDateSummaryButton"]

        func choose(month: String, year: String) {
            app.buttons["Choose month and year"].tap()
            let wheels = app.pickerWheels
            XCTAssertTrue(wheels.element(boundBy: 0).waitForExistence(timeout: 3))
            wheels.element(boundBy: 1).adjust(toPickerWheelValue: year)
            wheels.element(boundBy: 0).adjust(toPickerWheelValue: month)
            let start = wheels.element(boundBy: 0).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
                .withOffset(CGVector(dx: 0, dy: -18))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 350)))
            let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: wheels.element(boundBy: 0))
            XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 5), .completed)
        }
        choose(month: "January", year: "2028")
        app.buttons["calendarDay31"].tap()
        let timeAndZone = summary.label.components(separatedBy: ",").dropFirst().joined(separator: ",")
        choose(month: "February", year: "2028")
        XCTAssertTrue(summary.label.contains("29 Feb 2028"))
        XCTAssertEqual(summary.label.components(separatedBy: ",").dropFirst().joined(separator: ","), timeAndZone)
        choose(month: "February", year: "2027")
        XCTAssertTrue(summary.label.contains("28 Feb 2027"))
        XCTAssertEqual(summary.label.components(separatedBy: ",").dropFirst().joined(separator: ","), timeAndZone)
        app.buttons["startDateSummaryButton"].tap()
        choose(month: "January", year: "2026")
        XCTAssertTrue(app.buttons["startDateSummaryButton"].label.contains("Jan 2026"))
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
    }

    @MainActor
    func testMonthYearWheelsAcceptDirectSwipesAfterOpeningInFrench() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        app.buttons["settingsButton"].tap()
        app.buttons["settingsDateSelector0"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            for _ in 0..<2 {
                app.buttons["Choisir le mois et l’année"].tap()
                let month = app.pickerWheels["Mois"]
                let year = app.pickerWheels["Année"]
                XCTAssertTrue(month.exists)
                XCTAssertTrue(year.exists)
                let previousYear = year.value as? String
                let previousMonth = month.value as? String
                // No artificial delay or programmatic adjustment: a real swipe
                // must work on the first interaction following presentation.
                year.swipeUp(velocity: .slow)
                XCTAssertNotEqual(year.value as? String, previousYear)
                XCTAssertEqual(month.value as? String, previousMonth)
                if previousMonth == "Décembre" {
                    month.swipeDown(velocity: .slow)
                } else {
                    month.swipeUp(velocity: .slow)
                }
                XCTAssertNotEqual(month.value as? String, previousMonth)
                let start = month.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
                    .withOffset(CGVector(dx: 0, dy: -18))
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 350)))
                let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: month)
                XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 5), .completed)
            }
        }
    }

    @MainActor
    func testHomeClockCyclesAvailableZonesAndHiddenDotWithoutMovingTheLayout() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        app.buttons["targetDateCard0"].tap()
        app.buttons["settingsButton"].tap()
        app.buttons["settingsDateSelector0"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["English"].tap()

        app.buttons["closeSettingsButton"].tap()
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.buttons["closeSettingsButton"])
        XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 5), .completed)

        let clock = app.buttons["localClock"]
        func assertMode(_ value: String) {
            let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: clock)
            XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
        }
        for _ in 0..<4 {
            if clock.value as? String == "Local time" { break }
            clock.tap()
        }
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            assertMode("Local time")
            let clockFrame = clock.frame
            XCTAssertEqual(clockFrame.minX, 0, accuracy: 0.5)
            let settingsFrame = app.buttons["settingsButton"].frame
            let ring = app.descendants(matching: .any).matching(identifier: "daysRemaining").firstMatch
            XCTAssertTrue(ring.waitForExistence(timeout: 5))
            let ringFrame = ring.frame
            let cardFrame = app.buttons["targetDateCard0"].frame
            let visible = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            visible.name = "Clock visible — \(orientation.rawValue)"
            visible.lifetime = .keepAlways
            add(visible)
            var seen: [String] = []
            for _ in 0..<4 {
                let mode = clock.value as? String ?? ""
                XCTAssertFalse(seen.contains(mode))
                seen.append(mode)
                if mode == "Clock hidden" { break }
                XCTAssertTrue(["Local time", "Current time in the deadline time zone", "Current time in the start time zone"].contains(mode))
                clock.tap()
            }
            assertMode("Clock hidden")
            XCTAssertGreaterThanOrEqual(clock.frame.width, 44)
            XCTAssertGreaterThanOrEqual(clock.frame.height, 44)
            XCTAssertEqual(clock.frame.width, clockFrame.width, accuracy: 0.5)
            XCTAssertEqual(clock.frame.minX, 0, accuracy: 0.5)
            XCTAssertEqual(app.buttons["settingsButton"].frame.midX, settingsFrame.midX, accuracy: 0.5)
            XCTAssertEqual(app.buttons["settingsButton"].frame.midY, settingsFrame.midY, accuracy: 0.5)
            XCTAssertEqual(ring.frame.midY, ringFrame.midY, accuracy: 0.5)
            XCTAssertEqual(app.buttons["targetDateCard0"].frame.midY, cardFrame.midY, accuracy: 0.5)
            let hidden = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            hidden.name = "Clock hidden dot — \(orientation.rawValue)"
            hidden.lifetime = .keepAlways
            add(hidden)
            if orientation == .portrait {
                app.terminate()
                app.launch()
                assertMode("Clock hidden")
                app.buttons["targetDateCard1"].tap()
                assertMode("Clock hidden")
                app.buttons["targetDateCard0"].tap()
            }
            // Even the extreme left edge, well outside the dot, restores the clock.
            clock.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
                // Stay inside the rounded screen corner in landscape.
                .withOffset(CGVector(dx: orientation == .portrait ? 2 : 8, dy: 0)).tap()
            assertMode("Local time")
            for _ in 0..<3 {
                if clock.value as? String == "Clock hidden" { break }
                clock.tap()
            }
            assertMode("Clock hidden")
            // The invisible right side retains the whole visible clock's hit area.
            clock.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
                .withOffset(CGVector(dx: -2, dy: 0)).tap()
            assertMode("Local time")
        }

        // Leave the clock visible and restore the simulator's local-zone fixture.
        XCUIDevice.shared.orientation = .portrait
        app.buttons["settingsButton"].tap()
        for identifier in ["startDateSummaryButton", "targetDateSummaryButton"] {
            app.buttons[identifier].tap()
            app.buttons["Use local time zone"].tap()
            let save = app.buttons["validateDateButton"]
            if save.isEnabled { save.tap() }
        }
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
        app.buttons["closeSettingsButton"].tap()
    }

    @MainActor
    func testTimeZoneSheetUsesDragIndicatorWithoutCloseButton() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        app.buttons["settingsButton"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Choisir le fuseau horaire :")).firstMatch.tap()
        let title = app.staticTexts["Fuseau horaire"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["timeZoneSearchField"].exists)
        XCTAssertFalse(app.buttons["Fermer"].exists)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Time zone sheet — drag indicator"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let start = app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 0, dy: title.frame.minY - 12))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 560)))
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: title)
        XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 5), .completed)
        XCTAssertTrue(app.buttons["closeSettingsButton"].isHittable)
    }

    @MainActor
    func testSettingsTypographyInBothLanguagesAndOrientations() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = XCUIApplication()
        app.launch()
        app.buttons["settingsButton"].tap()
        app.buttons["settingsDateSelector0"].tap()
        for (language, subtitle) in [
            ("English", "Local time in this time zone"),
            ("Français", "Heure locale dans ce fuseau")
        ] {
            app.buttons["languageButton"].tap()
            app.buttons[language].tap()
            for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
                XCUIDevice.shared.orientation = orientation
                let localTime = app.staticTexts[subtitle]
                XCTAssertTrue(localTime.waitForExistence(timeout: 5))
                XCTAssertLessThanOrEqual(localTime.frame.height, 14)
                let now = app.buttons[language == "English" ? "Set deadline time to now" : "Définir heure de l’échéance à maintenant"]
                let localZone = app.buttons[language == "English" ? "Use local time zone" : "Utiliser le fuseau horaire local"]
                let time = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", language == "English" ? "Deadline time:" : "Heure de l’échéance :")).firstMatch
                let offset = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", language == "English" ? "Choose time zone:" : "Choisir le fuseau horaire :")).firstMatch
                XCTAssertEqual(now.frame.midX, localZone.frame.midX, accuracy: 0.5)
                XCTAssertEqual(time.frame.maxX, offset.frame.maxX, accuracy: 0.5)
                let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                screenshot.name = "Settings typography — \(language) — \(orientation.rawValue)"
                screenshot.lifetime = .keepAlways
                add(screenshot)
            }
            XCUIDevice.shared.orientation = .portrait
        }
        app.buttons["closeSettingsButton"].tap()
    }

    @MainActor
    func testSettingsHelpResetsLanguageOnEveryVisit() {
        let app = XCUIApplication()
        app.launch()
        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .portrait
        app.buttons["settingsButton"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let help = app.buttons["settingsHelpButton"]
            XCTAssertTrue(help.waitForExistence(timeout: 5))
            XCTAssertTrue(help.isHittable)
            XCTAssertGreaterThan(help.frame.minY, app.buttons["closeSettingsButton"].frame.minY)
            XCTAssertEqual(help.frame.midY, app.buttons["languageButton"].frame.midY, accuracy: 1)
            let globe = app.buttons["languageButton"]
            XCTAssertEqual(globe.frame.width, help.frame.width, accuracy: 1)
            XCTAssertEqual(globe.frame.height, help.frame.height, accuracy: 1)
            XCTAssertEqual(globe.frame.midY, help.frame.midY, accuracy: 1)
            XCTAssertLessThan(help.frame.maxX, globe.frame.minX)
            // Les contours débordent chacun de 0,5 pt dans les frames accessibles.
            XCTAssertEqual(globe.frame.minX - help.frame.maxX, 7, accuracy: 0.5)
            let settingsShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            settingsShot.name = "Settings help button — \(orientation.rawValue)"
            settingsShot.lifetime = .keepAlways
            add(settingsShot)
            for _ in 0..<2 {
                help.tap()
                XCTAssertTrue(app.buttons["helpLanguageButton"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.buttons["helpLanguageButton"].value as? String, "Français")
                XCTAssertFalse(app.staticTexts["À propos"].exists)
                let helpShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                helpShot.name = "Compact help header — \(orientation.rawValue)"
                helpShot.lifetime = .keepAlways
                add(helpShot)
                app.buttons["helpLanguageButton"].tap()
                app.buttons["helpLanguage-en"].tap()
                XCTAssertEqual(app.buttons["helpLanguageButton"].value as? String, "English")
                app.buttons["closeAboutButton"].tap()
                XCTAssertTrue(help.waitForExistence(timeout: 5))
                XCTAssertTrue(app.staticTexts["Paramètres"].exists)
                XCTAssertFalse(app.buttons["validateDateButton"].isEnabled)
            }
        }
        app.buttons["closeSettingsButton"].tap()
    }

    @MainActor
    func testHelpLanguageDoesNotChangeTheAppLanguage() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        for (appLanguage, localLanguage, heading, settingsTitle) in [
            ("Français", "en", "Your moments, at a glance.", "Paramètres"),
            ("English", "fr", "Vos repères, en un instant.", "Settings")
        ] {
            app.buttons["settingsButton"].tap()
            XCTAssertTrue(app.buttons["languageButton"].waitForExistence(timeout: 5))
            app.buttons["languageButton"].tap()
            app.buttons[appLanguage].tap()
            app.buttons["closeSettingsButton"].tap()
            app.buttons["aboutButton"].tap()
            XCTAssertTrue(app.buttons["helpLanguageButton"].waitForExistence(timeout: 5))
            app.buttons["helpLanguageButton"].tap()
            let option = app.buttons["helpLanguage-\(localLanguage)"]
            XCTAssertTrue(option.waitForExistence(timeout: 5))
            XCTAssertTrue(option.isHittable)
            option.tap()
            XCTAssertTrue(app.staticTexts[heading].waitForExistence(timeout: 5))
            app.buttons["closeAboutButton"].tap()
            app.terminate()
            app.launch()
            app.buttons["settingsButton"].tap()
            XCTAssertTrue(app.staticTexts[settingsTitle].waitForExistence(timeout: 5))
            app.buttons["closeSettingsButton"].tap()
            app.buttons["aboutButton"].tap()
            XCTAssertTrue(app.staticTexts[appLanguage == "Français" ? "Guide en français" : "Guide in English"].waitForExistence(timeout: 5))
            app.buttons["closeAboutButton"].tap()
        }
        app.buttons["settingsButton"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
        app.buttons["closeSettingsButton"].tap()
    }

    @MainActor
    func testHelpGuideFollowsAppLanguageAndScrollsThroughToSupport() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        for (language, headings) in [
            ("English", ["Your moments, at a glance.", "The main screen", "Choose the clock’s time zone", "Show or hide date and time", "Settings", "Handy shortcuts", "Help in your preferred language"]),
            ("Français", ["Vos repères, en un instant.", "L’écran principal", "Choisir le fuseau de l’horloge", "Afficher ou masquer date et heure", "Les paramètres", "Les petits raccourcis", "L’aide, dans la langue de votre choix"])
        ] {
            app.buttons["settingsButton"].tap()
            XCTAssertTrue(app.buttons["languageButton"].waitForExistence(timeout: 5))
            app.buttons["languageButton"].tap()
            app.buttons[language].tap()
            app.buttons["closeSettingsButton"].tap()
            XCTAssertTrue(app.buttons["aboutButton"].waitForExistence(timeout: 5))
            app.buttons["aboutButton"].tap()
            XCTAssertTrue(app.buttons["closeAboutButton"].waitForExistence(timeout: 5))
            let scroll = app.scrollViews.firstMatch
            XCTAssertFalse(app.staticTexts[language == "English" ? "Guide en français" : "Guide in English"].exists)
            for title in headings {
                let heading = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
                for _ in 0..<12 {
                    if heading.isHittable { break }
                    scroll.swipeUp()
                }
                XCTAssertTrue(heading.isHittable, title)
                let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                screenshot.name = "Guide — \(title)"
                screenshot.lifetime = .keepAlways
                add(screenshot)
            }
            let link = app.links["supportPrivacyLink"]
            for _ in 0..<12 {
                if link.isHittable { break }
                scroll.swipeUp()
            }
            XCTAssertTrue(link.isHittable)
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Guide — assistance"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            app.buttons["closeAboutButton"].tap()
            XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testAboutOpensAndClosesInBothOrientations() {
        let app = XCUIApplication()
        app.launch()
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let about = app.buttons["aboutButton"]
            XCTAssertTrue(about.waitForExistence(timeout: 10))
            XCTAssertTrue(about.isHittable)
            let settings = app.buttons["settingsButton"]
            if orientation == .portrait {
                XCTAssertEqual(about.frame.midY, settings.frame.midY, accuracy: 1)
                XCTAssertLessThan(about.frame.midX, settings.frame.midX)
                XCTAssertEqual(settings.frame.minX - about.frame.maxX, 7, accuracy: 0.5)
            } else {
                XCTAssertEqual(about.frame.midX, settings.frame.midX, accuracy: 1)
                XCTAssertEqual(about.frame.minY - settings.frame.maxY, 8, accuracy: 1)
            }
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Home help position — \(orientation.rawValue)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            about.tap()
            let close = app.buttons["closeAboutButton"]
            XCTAssertTrue(close.waitForExistence(timeout: 5))
            XCTAssertTrue(close.isHittable)
            XCTAssertEqual(app.buttons["helpLanguageButton"].frame.width, 48, accuracy: 1)
            XCTAssertGreaterThan(app.buttons["helpLanguageButton"].frame.midX, close.frame.midX)
            XCTAssertTrue(app.staticTexts["Untilia"].exists)
            XCTAssertTrue(app.staticTexts["appVersionLabel"].exists)
            XCTAssertEqual(app.staticTexts["Untilia"].frame.midY, app.buttons["helpLanguageButton"].frame.midY, accuracy: 1)
            XCTAssertTrue(app.links["supportPrivacyLink"].exists)
            let headerShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            headerShot.name = "Help handle and globe — \(orientation.rawValue)"
            headerShot.lifetime = .keepAlways
            add(headerShot)
            let handleStart = close.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            handleStart.press(forDuration: 0.05, thenDragTo: handleStart.withOffset(CGVector(dx: 0, dy: 120)))
            let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: close)
            XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
            let homeReady = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                app.buttons["aboutButton"].isHittable
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [homeReady], timeout: 5), .completed)
        }
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLaunchShowsCountdownAndSettings() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["languageButton"].waitForExistence(timeout: 5))
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
        app.buttons["closeSettingsButton"].tap()
        app.buttons["targetDateCard0"].tap()
        XCTAssertTrue(app.staticTexts["IL RESTE"].waitForExistence(timeout: 5))
        for index in 0..<3 {
            XCTAssertTrue(app.buttons["targetDateCard\(index)"].exists)
        }

        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["closeSettingsButton"].waitForExistence(timeout: 5))
        let validateDateButton = app.buttons["validateDateButton"]
        XCTAssertTrue(validateDateButton.exists)
        XCTAssertLessThanOrEqual(validateDateButton.frame.maxY, app.windows.firstMatch.frame.maxY)
        for index in 0..<3 {
            XCTAssertTrue(app.buttons["settingsDateSelector\(index)"].exists)
        }

        app.buttons["nameEditorButton"].tap()
        XCTAssertTrue(app.textFields["nameTextField"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Valider le nom"].exists)
        app.buttons["Valider le nom"].tap()

        let targetDateButton = app.buttons["targetDateSummaryButton"]
        let startDateButton = app.buttons["startDateSummaryButton"]
        XCTAssertTrue(targetDateButton.exists)
        XCTAssertTrue(startDateButton.exists)

        startDateButton.tap()
        XCTAssertTrue(app.staticTexts["HEURE DE DÉPART"].waitForExistence(timeout: 5))

        targetDateButton.tap()
        XCTAssertTrue(app.staticTexts["HEURE DE L’ÉCHÉANCE"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLanguageSwitchDoesNotDismissOrCrash() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["languageButton"].waitForExistence(timeout: 5))

        app.buttons["languageButton"].tap()
        let englishOption = app.buttons["English"]
        XCTAssertTrue(englishOption.waitForExistence(timeout: 5))
        englishOption.tap()

        XCTAssertTrue(app.buttons["languageButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))

        app.buttons["languageButton"].tap()
        let frenchOption = app.buttons["Français"]
        XCTAssertTrue(frenchOption.waitForExistence(timeout: 5))
        frenchOption.tap()

        XCTAssertTrue(app.staticTexts["Paramètres"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSettingsInitiallyMatchSelectedCardAndReopenWithoutChanges() throws {
        let app = XCUIApplication()
        app.launch()

        for index in [1, 2, 0] {
            let card = app.buttons["targetDateCard\(index)"]
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            card.tap()
            let cardLabel = card.label

            app.buttons["settingsButton"].tap()
            let closeButton = app.buttons["closeSettingsButton"]
            XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
            let nameLabel = app.buttons["nameEditorButton"].label
            XCTAssertFalse(nameLabel.isEmpty)
            XCTAssertFalse(app.buttons["validateDateButton"].isEnabled)
            closeButton.tap()

            XCTAssertTrue(card.waitForExistence(timeout: 5))
            XCTAssertEqual(card.label, cardLabel)
            app.buttons["settingsButton"].tap()
            XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
            XCTAssertEqual(app.buttons["nameEditorButton"].label, nameLabel)
            XCTAssertFalse(app.buttons["validateDateButton"].isEnabled)
            closeButton.tap()
        }
    }

    @MainActor
    func testCalendarSelectionRemainsInteractiveInBothOrientations() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        app.buttons["settingsButton"].tap()

        let day15 = app.buttons["calendarDay15"]
        XCTAssertTrue(day15.waitForExistence(timeout: 5))
        day15.tap()
        let summary = app.buttons["targetDateSummaryButton"]
        let day15Label = summary.label
        app.buttons["calendarDay16"].tap()
        XCTAssertNotEqual(summary.label, day15Label)

        XCUIDevice.shared.orientation = .landscapeLeft
        let day17 = app.buttons["calendarDay17"]
        XCTAssertTrue(day17.waitForExistence(timeout: 5))
        XCTAssertTrue(day17.isHittable)
        let day16Label = summary.label
        day17.tap()
        XCTAssertNotEqual(summary.label, day16Label)
        XCTAssertTrue(app.buttons["validateDateButton"].isEnabled)
    }

    @MainActor
    func testFixedHomeControlsStayInPlaceWhilePaging() {
        let app = XCUIApplication()
        app.launch()
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let first = app.buttons["targetDateCard0"]
            XCTAssertTrue(first.waitForExistence(timeout: 10))
            first.tap()
            let controls = [app.buttons["localClock"], app.buttons["aboutButton"],
                            app.buttons["settingsButton"]] + (0..<3).map { app.buttons["targetDateCard\($0)"] }
            let frames = controls.map(\.frame)
            let landscape = orientation != .portrait
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: landscape ? 0.4 : 0.75, dy: landscape ? 0.5 : 0.4))
            let end = start.withOffset(CGVector(dx: -app.frame.width * 0.3, dy: 0))
            print("FIXED_HOME_PARTIAL_DRAG_\(orientation.rawValue)")
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 3)
            // Releasing a held drag below half a page must cancel without changing selection.
            XCTAssertTrue(first.isSelected)
            let previewStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: landscape ? 0.84 : 0.4))
            let previewEnd = previewStart.withOffset(CGVector(dx: -app.frame.width * 0.6, dy: 0))
            print("EARLY_HOME_CONTOUR_\(orientation.rawValue)")
            previewStart.press(forDuration: 0.05, thenDragTo: previewEnd, withVelocity: .fast, thenHoldForDuration: 3)
            XCTAssertTrue(app.buttons["targetDateCard1"].isSelected)
            first.tap()
            XCTAssertTrue(first.isSelected)
            for index in [1, 2, 0] {
                app.swipeLeft()
                let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "selected == true"),
                                                         object: app.buttons["targetDateCard\(index)"])
                XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed)
                for (control, frame) in zip(controls, frames) {
                    if control.identifier == "localClock" {
                        XCTAssertEqual(control.frame.minX, frame.minX, accuracy: 0.5)
                    } else {
                        XCTAssertEqual(control.frame.midX, frame.midX, accuracy: 0.5)
                    }
                    XCTAssertEqual(control.frame.midY, frame.midY, accuracy: 0.5)
                }
                XCTAssertEqual(app.buttons.matching(identifier: "aboutButton").count, 1)
                XCTAssertEqual(app.buttons.matching(identifier: "targetDateCard0").count, 1)
            }
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Fixed home controls — \(orientation.rawValue)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
    }

    @MainActor
    func testHorizontalPagingAndCardSelectionInBothOrientations() throws {
        let app = XCUIApplication()
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()

        func assertSelected(_ index: Int, file: StaticString = #filePath, line: UInt = #line) {
            let card = app.buttons["targetDateCard\(index)"]
            let selected = NSPredicate(format: "selected == true")
            let expectation = XCTNSPredicateExpectation(predicate: selected, object: card)
            XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, file: file, line: line)
        }

        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let firstCard = app.buttons["targetDateCard0"]
            XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
            firstCard.tap()
            assertSelected(0)
            app.swipeLeft()
            assertSelected(1)
            app.swipeLeft()
            assertSelected(2)
            app.swipeLeft()
            assertSelected(0)
            app.swipeRight()
            assertSelected(2)
            app.swipeRight()
            assertSelected(1)
            app.swipeRight()
            assertSelected(0)
            app.swipeRight()
            assertSelected(2)
            app.swipeLeft()
            assertSelected(0)
            app.buttons["targetDateCard2"].tap()
            assertSelected(2)
            app.swipeRight()
            assertSelected(1)
            app.terminate()
            app.launch()
            assertSelected(1)
        }
    }

    @MainActor
    func testStatusCardHeightAndSelectionCardPositionsStayIdentical() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()

        for language in ["Français", "English"] {
            app.buttons["settingsButton"].tap()
            XCTAssertTrue(app.buttons["languageButton"].waitForExistence(timeout: 5))
            app.buttons["languageButton"].tap()
            app.buttons[language].tap()
            app.buttons["closeSettingsButton"].tap()

            for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
                XCUIDevice.shared.orientation = orientation
                let firstCard = app.buttons["targetDateCard0"]
                XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
                firstCard.tap()
                let status = app.otherElements["countdownProgressCard"]
                XCTAssertTrue(status.waitForExistence(timeout: 5))
                let statusFrame = status.frame
                let cardFrames = (0..<3).map { app.buttons["targetDateCard\($0)"].frame }

                for index in [1, 2, 0] {
                    let card = app.buttons["targetDateCard\(index)"]
                    card.tap()
                    let selected = XCTNSPredicateExpectation(
                        predicate: NSPredicate(format: "selected == true"), object: card
                    )
                    XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed)
                    XCTAssertEqual(status.frame.height, statusFrame.height, accuracy: 0.5)
                    XCTAssertEqual(status.frame.minY, statusFrame.minY, accuracy: 0.5)
                    for cardIndex in 0..<3 {
                        let frame = app.buttons["targetDateCard\(cardIndex)"].frame
                        XCTAssertEqual(frame.minY, cardFrames[cardIndex].minY, accuracy: 0.5)
                        XCTAssertEqual(frame.height, cardFrames[cardIndex].height, accuracy: 0.5)
                    }
                    if index == 2 {
                        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                        screenshot.name = "elapsed-card-\(language)-\(orientation.rawValue)"
                        screenshot.lifetime = .keepAlways
                        add(screenshot)
                    }
                }
            }
        }

        // Ne pas laisser le choix de langue du test influencer les tests suivants.
        app.buttons["settingsButton"].tap()
        app.buttons["languageButton"].tap()
        app.buttons["Français"].tap()
        app.buttons["closeSettingsButton"].tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
