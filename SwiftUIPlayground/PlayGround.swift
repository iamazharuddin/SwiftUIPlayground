//
//  PlayGround.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 16/10/25.
//

import SwiftUI
struct PlayGround: View {
    var body: some View {
        ShimmerView()
    }
}

#Preview {
    PlayGround()
}


struct ShimmerView: View {
    @State private var isAnimating:Bool = false
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.5))
            .frame(width: 150, height: 150)
            .overlay  {
                GeometryReader {
                    let size = $0.size
                    let shimmerWidth = size.width / 2.5
                    let height = size.height * 2
                    let minOffset:CGFloat = -size.width * 1.1
                    let maxOffset:CGFloat =  size.width * 1.1
                    Rectangle()
                        .fill(
                            Color.gray
                        )
                        .frame(width: shimmerWidth, height: height)
                        .rotationEffect(.degrees(5))
                        .blur(radius: size.width / 3)
                        .offset(x: isAnimating ? maxOffset : minOffset, y: -size.height/2)
                }
            }
            .animation(.linear.delay(1).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                    isAnimating = true
                }
            }
            .mask {
                Circle()
                    .frame(width: 150, height: 150)
            }
            .scaleEffect(isAnimating ? 1 : 0.5)
            .opacity(isAnimating ? 1 : 0.5)
    }
}
