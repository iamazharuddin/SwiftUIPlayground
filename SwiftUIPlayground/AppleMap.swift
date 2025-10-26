//
//  AppleMap.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 24/10/25.
//

import SwiftUI
struct AppleMap: View {
    @State private var showSheet: Bool = false
    var body: some View {
        VStack  {
            TabView {
                ForEach(Tabs.allCases, id:\.self) { tabItem  in
                    Tab {
                        Text(tabItem.rawValue)
                    } label: {
                        VStack(spacing: 12){
                            Text(tabItem.rawValue)
                            Image(systemName: tabItem.symbol)
                        }
                    }
                }
            }
            .task {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                VStack(alignment: .leading, spacing: 10)  {
                    
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .presentationDetents([.height(60), .medium, .large])
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
                .presentationBackgroundInteraction(.enabled(upThrough: .large))
                .interactiveDismissDisabled()
                .background {
                    CustomBackground()
                }
            }
        }
    }
}


struct CustomBackground : UIViewRepresentable  {
    func makeUIView(context: Context) ->  UIView {
        let view = UIView()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let sheetView = uiView.viewBeforeWindow()  {
                sheetView.frame = .init(origin: .init(x: 0, y: 0), size: .init(width: sheetView.frame.width, height: sheetView.frame.height - 60 - sheetView.safeAreaInsets.bottom))
                
                sheetView.clipsToBounds = true
                for subview in sheetView.subviews {
                    subview.layer.shadowColor = UIColor.clear.cgColor
                    
                    if subview.layer.animationKeys() != nil {
                        if let cornerRadiusView = subview.allSubView.first(where:  { $0.layer.animationKeys()?.contains("cornerRadius") ?? false  }) {
                            cornerRadiusView.layer.maskedCorners = []
                        }
                    }
                }
            }
        }
    }
}


extension UIView {
    func viewBeforeWindow() -> UIView? {
        if let superview = self.superview, superview is UIWindow {
            return  self
        }
        return superview?.viewBeforeWindow()
    }
    
    var allSubView: [UIView] {
        return self.subviews.flatMap { [$0] + $0.subviews  }
    }
}

#Preview {
    AppleMap()
}



fileprivate enum Tabs: String, CaseIterable {
    case people = "People"
    case devices = "Devices"
    case items = "Items"
    case me = "Me"
    
    var symbol : String {
        switch self {
        case .people:
            return "person.crop.circle.fill"
        case .devices:
            return "tv.fill"
        case .items:
            return "square.and.arrow.up.on.square.fill"
        case .me:
            return "person.circle.fill"
        }
    }
}
