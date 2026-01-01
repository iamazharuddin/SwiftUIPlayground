//
//  FullScreenSheetView.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 12/10/25.
//

import SwiftUI
struct FullScreenSheetContainerView: View {
    @State private var showSheet = false
    @Namespace private var animation
    var body: some View {
        NavigationStack {
            List {
                Button("Show Sheet") {
                    self.showSheet.toggle()
                }
                .matchedGeometryEffect(id: "BUTTON", in: animation)
            }
            .navigationTitle("Full-Screen Sheet")
            .fullScreenSheet(isPresented: $showSheet) {
                List {
                    ForEach(1...100, id:\.self) {
                        Text("Item \($0)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .monospaced()
                            .foregroundStyle(.white)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
//                .navigationTransition(.zoom(sourceID: "BUTTON", in: animation))
            } background: {
                 Rectangle()
                    .fill(Color.cyan.gradient)
            }
            
        }
    }
}

#Preview {
    FullScreenSheetContainerView()
}


struct FullScreenSheetView<Content:View, Background:View>: View {
    @ViewBuilder var content: () -> Content
    @ViewBuilder var background: () -> Background
    @State private var offset:CGFloat = 0
    @State private var scrollDisabled:Bool = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        content()
            .scrollDisabled(scrollDisabled)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            .offset(y: offset)
            .gesture(
                CustomPanGesture { gesture in
                    let state = gesture.state
                    let translation = min(max(gesture.translation(in: gesture.view).y, 0), windowSize.height)
                    
                    let halfHeight = windowSize.height / 2
                    let velocity = min(max(gesture.velocity(in: gesture.view).y / 5, 0), halfHeight)
                    
                    switch state {
                    case .began:
                        print("started")
                        scrollDisabled = true
                        offset = translation
                    case .changed:
                        guard scrollDisabled else { return }
                        offset  = translation
                    case .ended, .cancelled, .failed:
                        gesture.isEnabled = false
                        if translation + velocity > halfHeight {
                            withAnimation(.snappy(duration:0.3, extraBounce: 0)) {
                                offset = 0
                            }
                            Task {
                                try? await Task.sleep(for: .seconds(0.3))
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    dismiss()
                                }
                            }
                        } else {
                            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                offset = 0
                            }
                            
                            Task {
                                try? await Task.sleep(for: .seconds(0.3))
                                scrollDisabled = false
                                gesture.isEnabled = true
                            }
                        }
                    default: ()
                  }
               }
            )
            .presentationBackground {
                background()
                    .offset(y: offset)
            }
    }
    
    var windowSize: CGSize {
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow {
           return window.bounds.size
        }
        return .zero
    }
}


extension View {
    @ViewBuilder
    func fullScreenSheet<Content:View, Background:View>(
        showDragIndicator:Bool = true,
        isPresented:Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder background: @escaping () -> Background
    ) -> some View {
        self
            .fullScreenCover(isPresented: isPresented) {
                FullScreenSheetView(content: content, background: background)
            }
    }
}




fileprivate struct CustomPanGesture : UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer) -> Void
    
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }
    
    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        handle(recognizer)
    }
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            
            guard let pangesture =  gestureRecognizer as? UIPanGestureRecognizer  else {
                return false
            }
            
            let velocity = pangesture.velocity(in: pangesture.view).y
            
            var offset:CGFloat = 0
            if let cView = otherGestureRecognizer.view as? UICollectionView {
                offset = cView.contentOffset.y + cView.adjustedContentInset.top
            }
            
            if let sView = otherGestureRecognizer.view as? UIScrollView {
                offset = sView.contentOffset.y + sView.adjustedContentInset.top
            }
            
            
            let isEligible = Int(offset) <= 1 && velocity > 0
            
            return isEligible
        }
        
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
             let status =  gestureRecognizer.view?.gestureRecognizers?.contains(where: { ($0.name ?? "").localizedStandardContains("zoom") }) ?? false
            
            return !status
        }
    }
    
    
    
}
