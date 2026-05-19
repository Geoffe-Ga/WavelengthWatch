import SwiftUI

/// Central namespace for the WavelengthWatch design system.
///
/// Provides access to color, typography, and spacing tokens. Design-system
/// modifiers gate Liquid Glass directly via `if #available(watchOS 26, *)`
/// — there's no shared flag to consult.
enum WLTheme {
  typealias Colors = WLColorTokens
  typealias Typography = WLTypographyTokens
  typealias Spacing = WLSpacingTokens
}
