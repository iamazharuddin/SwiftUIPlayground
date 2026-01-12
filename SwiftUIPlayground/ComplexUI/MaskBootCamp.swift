//
//  MaskBootCamp.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 12/01/26.
//

import SwiftUI

struct MaskBootCamp: View {
    @State private var rating:Int = 0
    var body: some View {
        HStack {
            ForEach(0..<5) { index in
               Image(systemName: "star.fill")
                    .resizable()
                    .foregroundStyle(Color.gray)
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        rating = index + 1
                    }
                    .allowsHitTesting(true)
            }
        }
        .overlay {
            Rectangle()
                .fill(Color.yellow)
                .mask {
                    HStack {
                        ForEach(0..<5) { index in
                           Image(systemName: "star.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .opacity( index < rating ? 1 : 0)
                        }
                    }
                }
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    MaskBootCamp()
}
