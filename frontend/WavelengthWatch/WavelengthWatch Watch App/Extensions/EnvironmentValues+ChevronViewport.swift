import SwiftUI

extension EnvironmentValues {
  /// TEMPORARY (#457 Phase 0.2): the scroll viewport's global frame, published
  /// by `LayerScrollView`.
  ///
  /// Phase 0.1 judged the chevron against its own card and always returned
  /// `onscreen`, even when the chevron wasn't visible — because a card can be
  /// laid out *taller than the viewport* (observed `cardH` 257 vs the settled
  /// 193), pushing a bottom-anchored chevron below the visible area while still
  /// inside the card. Re-referencing the verdict against this viewport frame
  /// distinguishes that *overflow* failure (`offscreenBelow`) from a genuine
  /// *compositing* miss (`onscreen` yet invisible). Remove with the rest of the
  /// Phase 0 diagnostics once the RCA lands.
  @Entry var chevronDiagnosticViewportFrame: CGRect = .zero
}
