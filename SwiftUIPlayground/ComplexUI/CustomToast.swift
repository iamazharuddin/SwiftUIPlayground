//
//  CustomToast.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 20/10/25.
//

import SwiftUI

struct CustomToast: View {
    var body: some View {
        Text("CustomToast")
    }
}

#Preview {
    ToastManagerView()
}


struct ToastManagerView: View {
    @State private var window: UIWindow?
    var body: some View {
        ContentView()
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, window == nil  {
                    let window = PassThroughWindow(windowScene: windowScene)
                    
                    let rootController  = UIHostingController(rootView: CustomToast())
                    rootController.view.backgroundColor = .red
                    rootController.view.frame = windowScene.keyWindow?.bounds ?? .zero
                    window.rootViewController = rootController

                    window.isHidden = false
                    self.window = window
                }
            }
    }
}


class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view =  super.hitTest(point, with: event) else {
            return nil
        }
        return rootViewController?.view == view ? nil : view
    }
}
