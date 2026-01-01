//
//  SpotifyHome.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 27/10/25.
//

import SwiftUI

struct SpotifyHome: View {
    @State private var showAlert: Bool = false
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .onTapGesture {
                showAlert.toggle()
            }
            .alert("Alert", isPresented: $showAlert) {
                Button(role: .cancel) {
                    
                } label: {
                    Text("Cancel")
                }
                
                Button("Abort", role: .destructive) {
                    
                }
            } message: {
                Text("Alert Text")
            }.background {
                if showAlert {
                    AttachProgressWithAlert()
                }
            }
    }
}


struct AttachProgressWithAlert: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let currentController = windowScene.keyWindow?.rootViewController,
               let alertController  = currentController.presentedViewController as? UIAlertController
            {
                addProgreeView(alertController)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    private func addProgreeView( _ controller: UIAlertController) {
        let progressView = UIProgressView()
        progressView.tintColor = .systemBlue
        progressView.progress = 0.5
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        controller.view.addSubview(progressView)
        
        progressView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 16).isActive = true
        progressView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -16).isActive = true

        
        if let contentView = controller.view.getAllSubViews().first(where: {
            String(describing: type(of: $0)).contains("GroupHeaderScrollView") })  {
                print(contentView)
            
            let offset = contentView.frame.height
            
            
            progressView.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor, constant: offset - 12).isActive = true
        }
        
        controller.view.debugPrintSubviews()
    }
}

#Preview {
    SpotifyHome()
}


extension UIView {
    func getAllSubViews() -> [UIView] {
        var results: [UIView] = self.subviews.compactMap { $0 }
        for sub in self.subviews {
            results.append(contentsOf: sub.getAllSubViews())
        }
        return results
    }
}


extension UIView {
    func debugPrintSubviews(level: Int = 0) {
        let prefix = String(repeating: "  ", count: level)
        print("\(prefix)\(type(of: self))")
        subviews.forEach { $0.debugPrintSubviews(level: level + 1) }
    }
}
