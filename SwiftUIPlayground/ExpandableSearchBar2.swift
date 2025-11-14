//
//  ExpandableSearchBar.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 30/10/25.
//

import SwiftUI

struct ExpandableSearchBar2: View {
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ForEach(0..<100) { index in
                    cardView()
                }
            }
            .padding(15)
            .safeAreaInset(edge: .top) {
                ResizableHeader()
            }
        }
    }
    
    @ViewBuilder
    func ResizableHeader() -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome Back!")
                        .font(.callout)
                        .foregroundStyle(.gray)
                    
                    Text("iJustine")
                        .font(.title.bold())
                }
                
                Spacer(minLength: 0)
                
                Button {
                    
                } label: {
                    Image(.header)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal,15)
            .padding(.vertical,15)
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: .constant(""))
            }
            .padding(.horizontal,15)
            .padding(.vertical,12)
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        .background
                            .shadow(
                            .drop(
                                color: Color.black.opacity(0.08),
                                radius: 5,
                                x:5,
                                y:5
                            )
                            
                        )
                            .shadow(
                            .drop(
                                color: Color.black.opacity(0.08),
                                radius: 5,
                                x:-5,
                                y:-5
                            )
                            
                        )
                    )
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
    }
    
    @ViewBuilder
    func cardView() -> some View {
        VStack {
            GeometryReader { geometry in
                let size = geometry.size
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cyan)
                    .frame(width: size.width, height: size.height)
            }
            .frame(height: 220)
        }
    }
}

#Preview {
    ExpandableSearchBar2()
}
