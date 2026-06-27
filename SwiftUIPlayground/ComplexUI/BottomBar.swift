//
//  BottomBar.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 11/11/25.
//

import Foundation
import SwiftUI
struct AnimatedBottomBar<LeadingAction:View, TrailingAction:View, MainAction:View> : View {
    
    var hint: String
    var tint: Color = .green
    @Binding var text:String
    @FocusState.Binding var isFocused: Bool
    @ViewBuilder var leadingAction: () -> LeadingAction
    @ViewBuilder var trailingAction: () -> TrailingAction
    @ViewBuilder var mainAction: () -> MainAction
    
    @State private var isHighlighting: Bool = false
    
    var body: some View  {
        let mainLayout = isFocused ? AnyLayout(ZStackLayout(alignment: .bottomTrailing)) : AnyLayout(HStackLayout(alignment: .center, spacing: 10))
        let shape = RoundedRectangle(cornerRadius: isFocused ? 25 : 30)
        ZStack {
            mainLayout {
                let subLayout = isFocused ?
                       AnyLayout(VStackLayout(alignment: .trailing, spacing: 20))
                : AnyLayout(ZStackLayout(alignment: .bottomTrailing))
                subLayout {
                    TextField(hint, text: $text, axis: .vertical)
                        .lineLimit( isFocused ?  5 : 1)
                        .focused(_isFocused)
                        .mask {
                            Rectangle()
                                .padding(.trailing, isFocused ? 0 : 40)
                        }
                    
                    HStack(spacing: 10) {
                        HStack(spacing: 10) {
                            ForEach(subviews: leadingAction()) { subView in
                                subView
                                    .frame(width: 40, height: 40)
                                    .contentShape(.rect)
                            }
                        }
                        .compositingGroup()
                        .opacity(isFocused ? 1 : 0)
                        
                        Spacer(minLength: 0)
                        
                        trailingAction()
                            .frame(width: 40, height: 40)
                            .contentShape(.rect)
                    }
                }
                .frame(height: isFocused ? nil : 55)
                .padding(.leading, 15)
                .padding(.trailing, isFocused ? 15 : 10)
                .padding(.bottom, isFocused ? 10 : 0)
                .padding(.top, isFocused ? 20 : 0)
                .background {
                    shape
                        .fill(
                            .bar
                                .shadow(.drop(color: .black.opacity(0.1), radius: 5.0, x:5, y:5))
                                .shadow(.drop(color: .black.opacity(0.1), radius: 5.0, x:-5, y:-5))
                        )
                    HighlightingBackgroundView()
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "paperplane.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.black)
                        .frame(width: 20, height: 20)
                        .padding(15)
                        .contentShape(Circle())
                        .background {
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1),  radius: 5, x: 5, y:5)
                                .shadow(color: Color.black.opacity(0.1),  radius: 5, x: -5, y:-5)
                       }
                }
                .visualEffect { [isFocused] content, proxy in
                    content
                        .offset(x: isFocused ? proxy.size.width + 30 : 0)
                }
                

            }
            .geometryGroup()
        
        }
        .animation(.linear(duration: 0.3), value: isFocused)
    }
    
    @ViewBuilder
    func HighlightingBackgroundView() -> some View {
        let shape = RoundedRectangle(cornerRadius: isFocused ? 25 : 30)
        shape
            .stroke(
                Color.green.gradient,
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            .mask {
                let clearColors = Array(repeating: Color.clear, count: 2)
                 shape
                    .fill(
                        AngularGradient(colors: clearColors + [Color.white] + clearColors, center: .center, angle: .init(degrees: isHighlighting ? 360 : 0))
                    )
            }
            .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: isHighlighting)
            .onAppear() {
                isHighlighting.toggle()
            }
    }
}


#Preview {
    MYContent()
}


struct MYContent:View {
    @State private var text = ""
    @FocusState private var isFocused: Bool
    var body: some View {
        VStack {
            Spacer(minLength: 0)
            let fillColor = Color.gray.opacity(0.2)
            AnimatedBottomBar(hint: "Type Here ...", text: $text, isFocused: $isFocused) {
                Button {
                    
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(fillColor, in: .circle)
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "magnifyingglass")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(fillColor, in: .circle)
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "mic.fill")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(fillColor, in: .circle)
                }

            } trailingAction: {
                Button {
                    if isFocused {
                        isFocused = false
                    } else {
                        
                    }
                } label: {
                    Image(systemName: isFocused ? "checkmark" : "mic.fill")
                        .fontWeight(.medium)
                        .foregroundStyle( isFocused ? Color.green : Color.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background( isFocused ? Color.clear :  fillColor, in: .circle)
                }
            } mainAction: {
                
            }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }
}
