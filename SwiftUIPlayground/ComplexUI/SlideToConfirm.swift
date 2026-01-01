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
                    animatedText = true
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
    VStack(spacing: 40){
        SlideToConfirm()
        SlideToConfirm1()
    }
}



struct SlideToConfirm1: View {
    @State private var offsetX: CGFloat = 0
    @State private var animatedText: Bool = false
    var body: some View {
        GeometryReader {
            let size = $0.size
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: size.width, height: size.height)
                
                let maxLen = size.width - size.height
                let progress = offsetX / maxLen
                
                Capsule()
                    .fill(.green)
                    .frame(width: size.height +  maxLen * progress )
                
                HStack {
                    knobView(size, progress: progress)
                    shimmerTextView(size: size, knobSize: size.height, progress)
                }
            }
        }
        .frame(height: 50)
        .frame(maxWidth: 300, alignment: .center)
    }
    

    
    private func shimmerTextView(size:CGSize,  knobSize: CGFloat,  _ progress:CGFloat) -> some View {
//         Text("Slide to Pay")
//            .font(.system(size: 18, weight: .semibold))
//            .foregroundStyle(.gray)
//            .kerning(1)
//            .overlay {
//                Rectangle()
//                    .frame(width: 15)
//                    .visualEffect({ content, proxy in
//                        content
//                            .offset(x: -proxy.size.width)
//                            .offset(x: isAnimating ? proxy.size.width * 3 : 0)
//                    })
//                    .animation(
//                        .easeInOut(
//                            duration: 2.5
//                        ).repeatForever(
//                            autoreverses: false
//                        ),
//                        value: isAnimating
//                    )
//                    .onAppear() {
//                        isAnimating.toggle()
//                    }
//            }
//            .mask {
//                Text("Slide to Pay")
//            }
//            .frame(maxWidth: .infinity)
//            .frame(height: size.height)
        
        Text("Slide to Pay")
           .foregroundStyle(.gray.opacity(0.6))
           .overlay(content: {
               Rectangle()
                   .frame(height: 15)
                   .rotationEffect(.init(degrees: 90))
                   .visualEffect { content, proxy in
                       content
                           .offset(x: -proxy.size.width/1.8)
                           .offset(x: animatedText ? proxy.size.width * 1.2 : 0)
                   }
//                   .mask {
//                       Text("Slide to Pay")
//                   }
//                   .blendMode(.softLight)
           })
           .fontWeight(.semibold)
           .frame(maxWidth: .infinity)
//           .padding(.trailing, size.height / 2)
           .mask {
               Rectangle()
                    .scale( 1 - progress, anchor: .trailing)
           }
           .frame(height: size.height)
           .task {
               withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                   animatedText = true
               }
           }
    }
    
    private func knobView(_ size:CGSize,  progress: Double = 0) -> some View {
         Capsule()
            .fill(.background)
            .padding(6)
            .frame(width: size.height, height: size.height)
            .overlay(content: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .blur(radius: 10 * progress)
                    .opacity(1 - progress)
                
                Image(systemName: "checkmark")
                    .font(.title3.bold())
                    .blur(radius: 10 * (1-progress))
                    .opacity(progress)
            })
            .offset(x: offsetX)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let knobSize = size.height
                     let maxLen = size.width - knobSize
                     offsetX =  min(max(0,value.translation.width), maxLen)
                        print(value.translation.width)
                }
                .onEnded({ value in
                    let knobSize = size.height
                    let maxLen = size.width - knobSize
                    if  offsetX == maxLen {
                        print("confirm: \(value.translation.width )")
                    } else {
                        offsetX = 0
                    }
                })
            )
    }
}


