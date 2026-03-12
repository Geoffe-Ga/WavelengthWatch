import SwiftUI

// MARK: - Color Tokens Preview

#Preview("Color Tokens") {
  ScrollView {
    VStack(alignment: .leading, spacing: 8) {
      Text("LAYER COLORS")
        .font(WLTypographyTokens.sectionHeader)
        .tracking(WLTypographyTokens.sectionHeaderTracking)
        .foregroundColor(WLColorTokens.labelText)

      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
      ], spacing: 6) {
        colorSwatch("Beige", WLColorTokens.beige)
        colorSwatch("Purple", WLColorTokens.purple)
        colorSwatch("Red", WLColorTokens.red)
        colorSwatch("Blue", WLColorTokens.blue)
        colorSwatch("Orange", WLColorTokens.orange)
        colorSwatch("Green", WLColorTokens.green)
        colorSwatch("Yellow", WLColorTokens.yellow)
        colorSwatch("Teal", WLColorTokens.teal)
        colorSwatch("UV", WLColorTokens.ultraviolet)
        colorSwatch("Clear", WLColorTokens.clearLight)
        colorSwatch("Strat", WLColorTokens.strategies)
      }
    }
    .padding()
  }
  .background(Color.black)
}

// MARK: - Card Styles Preview

#Preview("Card Styles") {
  ScrollView {
    VStack(spacing: 12) {
      Text("Standard Card")
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .wlCard()

      Text("Tinted Card")
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .wlCard(tint: .blue)

      Text("Compact Card")
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .wlCard(compact: true)
    }
    .padding()
  }
  .background(Color.black)
}

// MARK: - Button Styles Preview

#Preview("Button Styles") {
  VStack(spacing: 16) {
    Button("Primary Action") {}
      .wlPrimaryButtonStyle()

    Button("Primary Tinted") {}
      .wlPrimaryButtonStyle(tint: .purple)

    Button("Secondary") {}
      .wlSecondaryButtonStyle()

    Button("Secondary Tinted") {}
      .wlSecondaryButtonStyle(tint: .blue)
  }
  .padding()
  .background(Color.black)
}

// MARK: - Glass Intensities Preview

#Preview("Glass Intensities") {
  VStack(spacing: 16) {
    Text("Regular Glass")
      .foregroundColor(.white)
      .padding()
      .wlGlass(.regular)

    Text("Prominent Glass")
      .foregroundColor(.white)
      .padding()
      .wlGlass(.prominent)

    Text("Tinted Glass")
      .foregroundColor(.white)
      .padding()
      .wlGlass(.regular, tint: .purple)
  }
  .padding()
  .background(Color.black)
}

// MARK: - Helper

private func colorSwatch(_ name: String, _ color: Color) -> some View {
  VStack(spacing: 2) {
    Circle()
      .fill(color)
      .frame(width: 24, height: 24)
      .shadow(color: color, radius: 2)
    Text(name)
      .font(.system(size: 8))
      .foregroundColor(.white.opacity(0.7))
  }
}
