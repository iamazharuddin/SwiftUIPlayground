//
//  VerifyMobileNumberSheet.swift
//  SwiftUIPlayground
//
//  Verify Mobile Number bottom sheet from AstroChat.
//  Figma: SDFication of AstroChat app — node 89:18541
//

import SwiftUI

struct VerifyMobileNumberSheet: View {
    var onVerify: () -> Void = {}
    var onBack: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            iconCircle
            VStack(spacing: 32) {
                textBlock
                buttons
            }
            .frame(width: 320)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
        .frame(width: 360)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 32,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 32,
                style: .continuous
            )
            .fill(Color.white)
        )
    }

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.12))
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.yellow)
        }
        .frame(width: 94, height: 94)
    }

    private var textBlock: some View {
        VStack(spacing: 6) {
            Text("Verify Mobile Number")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
                .lineSpacing(28 - 18)
                .multilineTextAlignment(.center)

            Text("To use AstroChat, you need to verify your mobile number on Shaadi App")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .lineSpacing(24 - 14)
                .multilineTextAlignment(.center)
                .frame(width: 278)
        }
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            AstroButton(
                title: "Verify Mobile Number",
                style: .filled,
                size: .large,
                onClick: onVerify
            )
            AstroButton(
                title: "Back to Shaadi.com",
                style: .text,
                size: .large,
                onClick: onBack
            )
        }
    }
}

struct VerifyMobileNumberSheetDemo: View {
    @State private var isPresented = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack {
                Spacer()
                Button("Show sheet") { isPresented = true }
                    .buttonStyle(.borderedProminent)
                Spacer()
            }
        }
        .sheet(isPresented: $isPresented) {
            VerifyMobileNumberSheet(
                onVerify: { isPresented = false },
                onBack: { isPresented = false }
            )
            .presentationDetents([.height(388)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
    }
}

#Preview("Sheet only") {
    VerifyMobileNumberSheet()
        .background(Color.black.opacity(0.5))
}

#Preview("Demo") {
    VerifyMobileNumberSheetDemo()
}
