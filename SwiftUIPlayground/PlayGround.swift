//
//  PlayGround.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 16/10/25.
//

import SwiftUI
struct PlayGround: View {
    var body: some View {
        List {
            Text("HELLO")
        }
        .listStyle(.plain)
        .background(CustomView())
        .sheet(isPresented: .constant(true)) {
            SheetView()
                .presentationDetents([.fraction(0.4), .fraction(0.99)])
                .presentationCornerRadius(0)
                .presentationBackground(.clear)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.5)))
                .background(CustomBackgroundView())
        }
    }
}


struct CustomView : UIViewRepresentable  {
    func makeUIView(context: Context) -> some UIView {
        let view  = UIView(frame: .zero)
        DispatchQueue.main.async {
            if let collectionView = view.window?.getUICollectionView() {
                collectionView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

struct CustomBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) ->  UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            if  let windowView =  view.getBeforeWindow() {
                for subview in windowView.subviews {
                   subview.layer.shadowColor = UIColor.clear.cgColor
                }
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

extension UIView {
    func getBeforeWindow() -> UIView? {
         if let superview, superview is UIWindow {
            return self
         }
         return superview?.getBeforeWindow()
    }
}

struct SheetView: View {
    var body: some View {
        Text("Sheet View")
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity)
            .background(Color.white.shadow(.drop(radius: 5.0)), in: .rect(cornerRadius: 25))
            .padding(15)
    }
}

#Preview {
    PlayGround()
}



extension UIView {
    func getUICollectionView() -> UICollectionView? {
        if  self is UICollectionView {
            return self as? UICollectionView
        }
        for view in subviews {
            if let found  = view.getUICollectionView() {
               return found
            }
        }
        return nil
    }
}
