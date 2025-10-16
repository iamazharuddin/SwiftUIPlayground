//
//  SlideToConfirm.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 11/10/25.
//

import SwiftUI

struct SlideToConfirm: View {
    @State private var animatedText:Bool = false
    @State private var offsetX:CGFloat = 0
    @State private var isCompleted:Bool = false
    var body: some View {
        VStack {
            Spacer()
            
            GeometryReader { geometry in
                let size = geometry.size
              
                
                let knobSize:CGFloat = size.height
                let maxLimit = size.width - knobSize
                
                let progress:CGFloat = offsetX / maxLimit
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            .gray.opacity(0.25)
                            .shadow(.inner(color: Color.black.opacity(0.2), radius: 10))
                        )
                    
                    let extraCapsuleWidth = (size.width - knobSize) * progress
                    Capsule()
                        .fill(Color.green.gradient)
                        .frame(width: knobSize + extraCapsuleWidth, height: knobSize)
                    
                    LeadingTextView(size, progress)
                    
                    HStack(spacing: 0){
                        knobView(size, progress, maxLimit)
                            .zIndex(1)
                        shimmerTextView(size, progress)
                    }
                }
            }
            .frame(height: 50)
            .containerRelativeFrame(.horizontal) { value, _ in
                value * 0.8
            }
            .frame(maxWidth: 300)
        }
    }
    
    
    func knobView( _ size: CGSize, _ progress:CGFloat, _ maxLimit:CGFloat) -> some View {
         Circle()
            .fill(.background)
            .padding(6)
            .frame(width: size.height, height: size.height)
            .overlay {
                ZStack {
                    Image(systemName: "chevron.right")
                        .opacity(1 - progress)
                        .blur(radius: progress * 10)
                    
                    Image(systemName: "checkmark")
                        .opacity(progress)
                        .blur(radius: (1 - progress) * 10)
                }
                .font(.title3.bold())
            }
            .contentShape(.circle)
            .offset(x: offsetX)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let knowSize  = size.height
                        let maxLimit = size.width - knowSize
                        print("\(value.translation.width)")
                        offsetX = min(max(value.translation.width, 0), maxLimit)
                        isCompleted = false
                    }.onEnded({ value  in
                        if offsetX == maxLimit {
                            print("Completed")
                            animatedText = false
                        } else {
                            withAnimation(.smooth) {
                                offsetX = 0
                                isCompleted = true
                            }
                        }
                    })
            )
    }
    
    func shimmerTextView( _ size: CGSize, _ progress:CGFloat) -> some View {
         Text("Slide to Pay")
            .foregroundStyle(.gray.opacity(0.6))
            .overlay(content: {
                Rectangle()
                    .frame(height: 15)
                    .rotationEffect(.init(degrees: 90))
                    .visualEffect { [animatedText] content, proxy in
                        content
                            .offset(x: -proxy.size.width/1.8)
                            .offset(x: animatedText ? proxy.size.width * 1.2 : 0)
                    }
                    .mask {
                        Text("Slide to Pay")
                    }
                    .blendMode(.softLight)
            })
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.trailing, size.height / 2)
            .mask {
                Rectangle()
                     .scale( 1 - progress, anchor: .trailing)
            }
            .frame(height: size.height)
            .task {
                withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    animatedText.toggle()
                }
            }
    }
    
    
    func LeadingTextView(  _ size: CGSize, _ progress:CGFloat) -> some View {
         Text("Confirm Payment")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.trailing, size.height / 2)
            .mask {
                Rectangle()
                    .scale(x: progress, anchor: .leading)
            }
    }
}

#Preview {
    SlideToConfirm()
}
