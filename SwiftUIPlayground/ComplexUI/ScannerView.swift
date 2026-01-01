//
//  ScannerView.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 24/10/25.
//

import SwiftUI
struct ScannerView: View {
    @State private var isAnimate:Bool = false
    var body: some View {
        VStack {
            Spacer(minLength: 0)
            GeometryReader { proxy in
                let size  = proxy.size
                ZStack(alignment: .top) {
                    ForEach(0..<4, id:\.self) { index in
                        let angle = index * 90
                        RoundedRectangle(cornerRadius: 4.0)
                            .trim(from: 0.65, to:0.7)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                            .rotationEffect(.degrees(Double(angle)))
                            .onAppear() {
                                print("angle = \(angle)")
                            }
                    }
                    
                    Rectangle()
                        .frame(height: 8.0)
                        .opacity(0.3)
                        .shadow(color: Color.gray, radius: 5, x:0, y: isAnimate ? 15 : -15)
                        .offset(y: isAnimate ? size.height : 0)
                        .animation(.easeInOut(duration: 2.0).delay(0.1).repeatForever(autoreverses: true), value: isAnimate)
                }
                .frame(width: size.width, height: size.height)
                .onAppear() {
                    isAnimate = true
                }
            }
            .padding(.horizontal, 45)
            
            Spacer(minLength: 45)
            
            Button {
                
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
            }
            
            Spacer(minLength: 45)
        }
    }
}



#Preview {
    ScannerView()
}
