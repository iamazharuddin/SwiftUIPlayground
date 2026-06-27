//
//  IOS26GlassBottomSheetDemo.swift
//  SwiftUIPlayground
//

import SwiftUI

private struct DemoSpot: Identifiable {
    let id = UUID()
    let name: String
    let area: String
    let distance: String
    let symbolName: String
}

private let demoSpots: [DemoSpot] = [
    DemoSpot(name: "Riverside Walk", area: "Waterfront", distance: "0.4 mi", symbolName: "figure.walk"),
    DemoSpot(name: "Copper Oak Café", area: "Old Town", distance: "0.8 mi", symbolName: "cup.and.saucer.fill"),
    DemoSpot(name: "North Park Studio", area: "Arts District", distance: "1.1 mi", symbolName: "paintpalette.fill"),
    DemoSpot(name: "Harbor Lookout", area: "Marina", distance: "1.6 mi", symbolName: "binoculars.fill"),
    DemoSpot(name: "Elm Street Books", area: "Downtown", distance: "2.0 mi", symbolName: "books.vertical.fill"),
]

/// Bottom sheet using system detents (Liquid Glass on iOS 26+) and a glass header bar.
struct IOS26GlassBottomSheetDemo: View {
    @State private var showSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.indigo.opacity(0.9), .cyan.opacity(0.75), .mint.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Glass bottom sheet")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Present a medium/large sheet; the header uses liquid glass on iOS 26.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 28)

                    Button("Open sheet") {
                        showSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.indigo)
                }
            }
            .navigationTitle("Playground")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: $showSheet) {
                GlassBottomSheetContent(spots: demoSpots)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct GlassBottomSheetContent: View {
    let spots: [DemoSpot]
    @Environment(\.dismiss) private var dismiss

    /// At `.large`, the system sheet chrome becomes opaque to content *behind* the sheet, so liquid glass
    /// in the header loses its “see-through” look. A full-bleed gradient *inside* the sheet keeps pixels
    /// behind the header at every detent.
    private var sheetInteriorBackdrop: some View {
        LinearGradient(
            stops: [
                .init(color: .indigo.opacity(0.55), location: 0),
                .init(color: .cyan.opacity(0.42), location: 0.22),
                .init(color: .mint.opacity(0.28), location: 0.38),
                .init(color: Color(uiColor: .systemBackground), location: 0.72),
                .init(color: Color(uiColor: .secondarySystemGroupedBackground), location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            sheetInteriorBackdrop
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(spots) { spot in
                            spotRow(spot)
                            if spot.id != spots.last?.id {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var sheetHeader: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nearby")
                            .font(.title3.weight(.semibold))
                        Text("Dummy places near you")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular, in: Circle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nearby")
                        .font(.title3.weight(.semibold))
                    Text("Dummy places near you")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary, .quaternary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
    }

    private func spotRow(_ spot: DemoSpot) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: spot.symbolName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.body.weight(.medium))
                Text(spot.area)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(spot.distance)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview("Glass bottom sheet") {
    IOS26GlassBottomSheetDemo()
}
