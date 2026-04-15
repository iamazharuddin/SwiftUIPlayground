//
//  IOS26GlassBottomSheetHeaderOnly.swift
//  SwiftUIPlayground
//
//  Sheet variant: liquid glass applied only on the header bar; list uses standard surfaces.
//

import SwiftUI

private struct HeaderOnlyDemoSpot: Identifiable {
    let id = UUID()
    let name: String
    let area: String
    let distance: String
    let symbolName: String
}

private let headerOnlyDemoSpots: [HeaderOnlyDemoSpot] = [
    HeaderOnlyDemoSpot(name: "Riverside Walk", area: "Waterfront", distance: "0.4 mi", symbolName: "figure.walk"),
    HeaderOnlyDemoSpot(name: "Copper Oak Café", area: "Old Town", distance: "0.8 mi", symbolName: "cup.and.saucer.fill"),
    HeaderOnlyDemoSpot(name: "North Park Studio", area: "Arts District", distance: "1.1 mi", symbolName: "paintpalette.fill"),
    HeaderOnlyDemoSpot(name: "Harbor Lookout", area: "Marina", distance: "1.6 mi", symbolName: "binoculars.fill"),
    HeaderOnlyDemoSpot(name: "Elm Street Books", area: "Downtown", distance: "2.0 mi", symbolName: "books.vertical.fill"),
]

/// Same idea as `IOS26GlassBottomSheetDemo`, but **one** glass shape wraps the full header; scroll content is plain grouped style.
struct IOS26GlassBottomSheetHeaderOnlyDemo: View {
    @State private var showSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Header-only glass")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Sheet list uses system surfaces; only the sheet header uses `.glassEffect` on iOS 26.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button("Open sheet") {
                    showSheet = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Playground")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSheet) {
                GlassBottomSheetHeaderOnlyContent(spots: headerOnlyDemoSpots)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
            }
        }
    }
}

private struct GlassBottomSheetHeaderOnlyContent: View {
    let spots: [HeaderOnlyDemoSpot]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var headerBar: some View {
        if #available(iOS 26, *) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nearby")
                        .font(.title3.weight(.semibold))
                    Text("Dummy places near you")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nearby")
                        .font(.title3.weight(.semibold))
                    Text("Dummy places near you")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
        }
    }

    private func spotRow(_ spot: HeaderOnlyDemoSpot) -> some View {
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

#Preview("Header-only glass sheet") {
    IOS26GlassBottomSheetHeaderOnlyDemo()
}
