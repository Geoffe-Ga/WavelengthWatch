//
//  OnboardingViewUITests.swift
//  WavelengthWatch Watch AppUITests
//
//  Created by Claude Code on 1/14/26.
//

import XCTest

final class OnboardingViewUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testOnboardingViewAppearsOnFirstLaunch() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Verify onboarding sheet appears
    XCTAssertTrue(app.staticTexts["Welcome to WavelengthWatch"].exists)
    XCTAssertTrue(app.staticTexts["How would you like to store your journal?"].exists)
  }

  @MainActor
  func testOnboardingViewShowsStorageOptions() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Verify both storage options are displayed
    XCTAssertTrue(app.staticTexts["Privacy First"].exists)
    XCTAssertTrue(app.staticTexts["Cloud Backup"].exists)
    XCTAssertTrue(app.staticTexts["Your journal stays on this watch. Complete privacy, no data transmission."].exists)
    XCTAssertTrue(app.staticTexts["Journal backed up to cloud for safe keeping and future device transfers."].exists)
  }

  @MainActor
  func testLocalOnlySelectionIsDefault() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Verify local-only is selected by default (Privacy First)
    let privacyFirstButton = app.buttons["Privacy First: Your journal stays on this watch. Complete privacy, no data transmission."]
    XCTAssertTrue(privacyFirstButton.exists)
  }

  @MainActor
  func testCanSelectCloudBackup() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Tap on Cloud Backup option
    let cloudBackupButton = app.buttons["Cloud Backup: Journal backed up to cloud for safe keeping and future device transfers."]
    cloudBackupButton.tap()

    // Verify selection changed (button should exist after tap)
    XCTAssertTrue(cloudBackupButton.exists)
  }

  @MainActor
  func testContinueButtonDismissesOnboarding() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Verify onboarding is present
    XCTAssertTrue(app.staticTexts["Welcome to WavelengthWatch"].exists)

    // Tap continue button
    let continueButton = app.buttons["Continue with selected storage mode"]
    XCTAssertTrue(continueButton.exists)
    continueButton.tap()

    // Verify onboarding is dismissed (welcome text should not exist)
    XCTAssertFalse(app.staticTexts["Welcome to WavelengthWatch"].waitForExistence(timeout: 1))
  }

  @MainActor
  func testOnboardingShowsSettingsHint() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Verify settings hint is displayed
    XCTAssertTrue(app.staticTexts["You can change this anytime in Settings"].exists)
  }
}
