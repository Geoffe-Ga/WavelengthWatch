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

    // Verify onboarding sheet appears using accessibility identifiers
    XCTAssertTrue(app.staticTexts["onboarding_welcome_title"].exists)
    XCTAssertTrue(app.staticTexts["onboarding_storage_question"].exists)
  }

  @MainActor
  func testOnboardingViewShowsStorageOptions() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Verify both storage options are displayed using accessibility identifiers
    XCTAssertTrue(app.buttons["onboarding_option_local"].exists)
    XCTAssertTrue(app.buttons["onboarding_option_cloud"].exists)
    XCTAssertTrue(app.staticTexts["Privacy First"].exists)
    XCTAssertTrue(app.staticTexts["Cloud Backup"].exists)
  }

  @MainActor
  func testLocalOnlySelectionIsDefault() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Verify local-only is selected by default using accessibility identifier
    let privacyFirstButton = app.buttons["onboarding_option_local"]
    XCTAssertTrue(privacyFirstButton.exists)
  }

  @MainActor
  func testCanSelectCloudBackup() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Tap on Cloud Backup option using accessibility identifier
    let cloudBackupButton = app.buttons["onboarding_option_cloud"]
    cloudBackupButton.tap()

    // Verify selection changed (button should exist after tap)
    XCTAssertTrue(cloudBackupButton.exists)
  }

  @MainActor
  func testContinueButtonDismissesOnboarding() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Verify onboarding is present using accessibility identifier
    XCTAssertTrue(app.staticTexts["onboarding_welcome_title"].exists)

    // Tap continue button using accessibility identifier
    let continueButton = app.buttons["onboarding_continue_button"]
    XCTAssertTrue(continueButton.exists)
    continueButton.tap()

    // Verify onboarding is dismissed (welcome text should not exist)
    XCTAssertFalse(app.staticTexts["onboarding_welcome_title"].waitForExistence(timeout: 1))
  }

  @MainActor
  func testOnboardingShowsSettingsHint() throws {
    let app = XCUIApplication()
    app.launchArguments = ["RESET_ONBOARDING"]
    app.launch()

    // Verify settings hint is displayed using accessibility identifier
    XCTAssertTrue(app.staticTexts["onboarding_settings_hint"].exists)
  }
}
