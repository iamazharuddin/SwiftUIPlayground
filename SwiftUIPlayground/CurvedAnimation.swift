//
//  CurvedAnimation.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 17/10/25.
//

import SwiftUI
struct CurvedAnimation: View {
    @State private var isAnimating = false
    var body: some View {
        ZStack {
            curvedPath
                .stroke(Color.gray, style: StrokeStyle(lineWidth: 2.0, dash: [6] ))
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .modifier(MoveAlongPath(path: curvedPath, pct: isAnimating ? 1 : 0))
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: false)) {
                        isAnimating.toggle()
                    }
                }
        }
    }
    
    var curvedPath: Path {
        var path = Path()
        path.move(to: CGPoint(x: 50, y: 400))
        path.addQuadCurve(to: CGPoint(x: 300, y: 400), control: CGPoint(x: 200, y: 100))
        return path
    }
}

#Preview {
    CurvedAnimation()
}


struct MoveAlongPath : AnimatableModifier  {
      let path: Path
       var pct: CGFloat
    
     var animatableData: CGFloat {
        get { pct }
        set { pct = newValue }
     }
    
     func body(content: Content) -> some View {
          let point = path.point(at: pct)
          return content.position(point)
     }
}

extension Path {
    func point(at percent: CGFloat) -> CGPoint {
        let trimmed = self.trimmedPath(from: 0, to: percent)
        return trimmed.currentPoint ?? .zero
    }
}
