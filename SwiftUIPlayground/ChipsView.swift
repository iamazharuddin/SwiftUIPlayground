//
//  ChipsView.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 11/10/25.
//

import SwiftUI

struct ChipsView: View {
    let tags:[String] = ["Apple", "Banana", "Orange", "Mango", "Pineapple", "Apple", "Banana", "Orange", "Mango", "Pineapple", "Apple"]
    var body: some View {
        ChipsLayout {
            ForEach(tags, id:\.self) { tag in
                Text(tag)
                    .fontWeight(.semibold)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(.white)
            }
        }
        .padding(15)
        .background(Color.gray.opacity(0.1), in: .rect(cornerRadius: 20, style: .circular))
        .padding(15)
    }
}

#Preview {
    ChipsView()
}


struct ChipsLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let height = maxHeight(proposal: proposal, subviews: subviews)
        print(height)
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var orignin = bounds.origin
        for subview in subviews {
            let fitsize = subview.sizeThatFits(proposal)
            
            if  orignin.x + fitsize.width > bounds.maxX {
                orignin.x = bounds.minX
                orignin.y += fitsize.height + 10
                
                subview.place(at: orignin, proposal: proposal)
                orignin.x += fitsize.width + 10
            } else {
                subview.place(at: orignin, proposal: proposal)
                orignin.x += fitsize.width + 10
            }
        }
    }
    
    
    private func maxHeight(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        var orignin = CGPoint(x: 0, y: 0)
        
        for subview in subviews {
            let fitsize = subview.sizeThatFits(proposal)
            
            if  orignin.x + fitsize.width > (proposal.width ?? 0) {
                orignin.x = 0
                
                orignin.y += fitsize.height + 10
                orignin.x += fitsize.width + 10
            } else {
                orignin.x += fitsize.width + 10
            }
            
            if  subview == subviews.last {
                orignin.y += fitsize.height
            }
        }
        
        return orignin.y
    }
    
    
}
