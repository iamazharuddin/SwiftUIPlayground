//
//  SkeletonView.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 11/10/25.
//

import SwiftUI
struct SkeletonView<S: Shape>: View {
    let shape: S
    let color: Color
    @State private var isAnimating = false
    var body: some View {
        shape
            .fill(color)
            .overlay {
                GeometryReader { proxy in
                    let size = proxy.size
                    
                    let height = size.height, skeletonWidth = size.width / 2
                    let blurRadius = max(skeletonWidth / 2, 30)
                    let blurDiameter = blurRadius * 2
                    
                    let minX = -(skeletonWidth  + blurDiameter)
                    let maxX = size.width + skeletonWidth + blurDiameter
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: skeletonWidth, height: height * 2)
                        .frame(height: height)
                        .blur(radius: blurRadius)
                        .rotationEffect(.init(degrees: 5))
                        .blendMode(.softLight)
                        .offset(x: isAnimating ? maxX : minX)
                }
            }
            .clipShape(shape)
            .compositingGroup()
            .onAppear {
                guard !isAnimating else { return }
                withAnimation(.easeIn(duration: 1.5).repeatForever(autoreverses: false)) {
                    self.isAnimating.toggle()
                    print("isAnimating = \(isAnimating)")
                }
            }
            .onDisappear() {
                isAnimating = false
            }
            .onTapGesture {
                isAnimating = !isAnimating
            }
            .transaction { transaction in
                if transaction.animation != nil {
                    transaction.animation = nil
                }
            }
    }
}

#Preview {
    @Previewable
    @State var isAnimating: Bool = false
    VStack(spacing: 20) {
          CardSkeletonView()
          CardSkeletonView()
      }
      .padding()
      .onTapGesture {
          isAnimating = !isAnimating
      }
}


struct CardSkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Profile circle
            SkeletonView(shape: Circle(), color: .gray.opacity(0.3))
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 12) {
                // Title rectangle
                SkeletonView(shape: RoundedRectangle(cornerRadius: 6), color: .gray.opacity(0.3))
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)

                // Subtitle rectangles
                SkeletonView(shape: RoundedRectangle(cornerRadius: 6), color: .gray.opacity(0.3))
                    .frame(height: 14)
                    .frame(maxWidth: 200)

                SkeletonView(shape: RoundedRectangle(cornerRadius: 6), color: .gray.opacity(0.3))
                    .frame(height: 14)
                    .frame(maxWidth: 150)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2, y: 1)
        .padding()
    }
}
