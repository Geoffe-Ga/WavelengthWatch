import SwiftUI
import Testing

@testable import WavelengthWatch_Watch_App

/// Tests for MysticalJournalIcon component.
///
/// The icon displays a plus sign within a glowing circle border,
/// used to indicate tappable journal entry points in curriculum cards.
@Suite("MysticalJournalIcon Tests")
struct MysticalJournalIconTests {
  @Test func mysticalJournalIcon_initializesWithColor() {
    // Verify the icon can be created with different colors
    let blueIcon = MysticalJournalIcon(color: .blue)
    let redIcon = MysticalJournalIcon(color: .red)
    let greenIcon = MysticalJournalIcon(color: .green)

    // The icon view should compile and initialize without errors
    // Implementation verified in ContentView.swift:946-976:
    // - Contains Circle with strokeBorder
    // - Contains Image(systemName: "plus") for the plus sign
    // - Has glowing animation on appear
    #expect(blueIcon.color == .blue)
    #expect(redIcon.color == .red)
    #expect(greenIcon.color == .green)
  }
}
