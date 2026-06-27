//
//  CustomCurve.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 19/10/25.
//

import SwiftUI

struct CustomCurve: View {
    var body: some View {
        Pentagon()
            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
            .frame(width: 200, height: 200)
    }
}




struct CustomCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.height/2, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        return  path
    }
}

#Preview {
    CustomCurve()
}


struct Pentagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // top Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // top right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // mid right
        path.addLine(to: CGPoint(
            x: rect.maxX,
            y: rect.midY
        ))
        
        
        // Bottom
        path.addLine(to: CGPoint(
            x: rect.midX,
            y: rect.maxY
        ))
        
        // mid left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        
        // top left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        return path
    }
}
