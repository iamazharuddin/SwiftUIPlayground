//
//  MaskBootCamp.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 12/01/26.
//

import SwiftUI

struct MaskBootCamp: View {
    var body: some View {
        HStack {
            ForEach(0..<5) { _ in
               Image(systemName: "star.fill")
            }
        }
    }
}

#Preview {
    MaskBootCamp()
}
