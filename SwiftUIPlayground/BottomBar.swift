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
    
    
    var body: some View  {
        let mainLayout = isFocused ? AnyLayout(ZStackLayout(alignment: .bottomTrailing)) : AnyLayout(HStackLayout(alignment: .bottom, spacing: 10))
        let shape = RoundedRectangle(cornerRadius: isFocused ? 25 : 30)
        ZStack {
            mainLayout {
                let subLayout = isFocused ?
                       AnyLayout(VStackLayout(alignment: .trailing, spacing: 20))
                     : AnyLayout(ZStackLayout(alignment: .trailing))
                subLayout {
                    TextField(hint, text: $text, axis: .vertical)
                        .lineLimit(5)
                        .focused(_isFocused)
                    
                    HStack(spacing: 10) {
                        ForEach(subviews: leadingAction()) { subView in
                            subView
                                .frame(width: 40, height: 40)
                                .contentShape(.rect)
                        }
                    }
                    .compositingGroup()
                    
                    Spacer(minLength: 0)
                    
                    trailingAction()
                        .frame(width: 40, height: 40)
                        .contentShape(.rect)
                }
                .frame(height: isFocused ? nil : 55)
                .padding(.leading, 15)
                .padding(.trailing, isFocused ? 15 : 10)
                .padding(.bottom, isFocused ? 10 : 0)
                .padding(.top, isFocused ? 20 : 0)
                .background {
                    shape
                        .fill(.bar)
                        .shadow(color: .black.opacity(0.1), radius: 5, x:0, y: 5)
                        .shadow(color: .black.opacity(0.1), radius: 5, x:0, y: -5)
                }
            }
        }
        .geometryGroup()
        .animation(.linear(duration: 1.0), value: isFocused)
    }
}


#Preview {
    Content()
}


private struct Content:View {
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
                    
                } label: {
                    Image(systemName: "mic.fill")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(fillColor, in: .circle)
                }
            } mainAction: {
                
            }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }
}
