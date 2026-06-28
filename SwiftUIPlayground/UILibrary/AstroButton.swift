//
//  AstroButton.swift
//  SwiftUIPlayground
//
//  Bare-minimum design-system button using built-in SwiftUI colors.
//  No asset or custom-color dependencies — caller passes an optional Image.
//

import SwiftUI

struct AstroButton: View {
    enum ButtonStyle {
        case filled, text, light, error
    }

    enum Size {
        case small, medium, large, extraLarge
    }

    var icon: Image?
    var title: String
    var style: ButtonStyle
    var size: Size
    var isEnabled: Bool = true
    var onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 8) {
                if let icon = icon {
                    icon
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
        }
        .allowsHitTesting(isEnabled)
    }

    private var height: CGFloat {
        switch size {
        case .large: return 44
        case .medium: return 40
        case .small: return 36
        case .extraLarge: return 48
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled: return isEnabled ? .orange : .gray
        case .text: return .clear
        case .light: return isEnabled ? .orange.opacity(0.12) : .gray
        case .error: return .red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled, .error: return .white
        case .text: return .orange
        case .light: return isEnabled ? .orange : .white
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AstroButton(title: "Accept", style: .filled, size: .large, onClick: {})
        AstroButton(title: "Accept", style: .light, size: .large, onClick: {})
        AstroButton(title: "Accept", style: .error, size: .large, onClick: {})
        AstroButton(title: "Accept", style: .text, size: .large, onClick: {})
    }
    .padding()
}
