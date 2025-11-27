//
//  StarView.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 17/10/25.
//

import SwiftUI
struct StarView: View {
    @State private var rating = 4
    
    var body: some View {
        starView()
            .overlay {
                GeometryReader { proxy in
                    let width = (CGFloat(rating) / 5.0) * proxy.size.width
                    Rectangle()
                        .fill(.yellow)
                        .frame(width: width)
                        .animation(.easeInOut, value: rating)
                }
                .allowsHitTesting(false)
            }
            .mask(starView()) // Mask applied to the rectangle overlay
    }
    
    func starView() -> some View {
        HStack(spacing: 20) {
            ForEach(0..<5) { index in
                Image(systemName: "star.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.gray)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            rating = index + 1
                        }
                    }
            }
        }
    }
}

#Preview {
    AnimatedText()
}


struct AnimatedText: View {
    @State private var isAnimation: Bool = false
    var body: some View {
        Rectangle()
            .overlay(
                LinearGradient(colors: [.clear, .red, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 100)
                    .offset(x: isAnimation ? getWidth() / 2  : -getWidth() / 2)
            )
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: false), value: isAnimation)
            .mask {
                Text("Slide to shut down")
                    .foregroundStyle(.black)
                    .font(.largeTitle)
            }
            .background(Color.gray)
            .onAppear() {
                isAnimation.toggle()
            }
    }
    
    func getWidth() -> CGFloat {
        if let window = UIApplication.shared.connectedScenes.first as? UIWindowScene {
           return   window.keyWindow?.bounds.width ?? 0
        }
        return 0
    }
}
