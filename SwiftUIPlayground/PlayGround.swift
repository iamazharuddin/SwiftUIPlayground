import SwiftUI

struct PlayGround: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<30) { i in
                    Text("Row \(i)")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .background { ScrollDetector { offsetY in
                print("✅ Found UIScrollView:", offsetY)
             }
            }
        }
    }
}

#Preview {
    PlayGround()
}


struct ScrollDetector: UIViewRepresentable {
    var onScrollViewOffsetChnage: (CGFloat) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let scrollView = uiView.superview?.superview?.superview as? UIScrollView, !context.coordinator.isDelegateAdded {
                scrollView.delegate = context.coordinator
                context.coordinator.isDelegateAdded = true
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: ScrollDetector
        var isDelegateAdded = false
        init( _ parent: ScrollDetector) {
            self.parent = parent
        }
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            self.parent.onScrollViewOffsetChnage(scrollView.contentOffset.y)
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            
        }
    }
}
