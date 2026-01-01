//
//  SwiftUIPlaygroundApp.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 11/10/25.
//

import SwiftUI
import Combine
struct AlertMessage: Identifiable {
    var id: UUID = UUID()
    let data: Data
}

@main
struct SwiftUIPlaygroundApp: App {
    @UIApplicationDelegateAdaptor private var delegate: AppDelagate
    let downloadService = DownloadService.shared
    @State private var cancellables: Set<AnyCancellable> = []
    let observer = AppLifeCycleObserver()
    
    let urlString = "https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf"
    
    init() {
        performRequest()
    }
    
    @State private var alertMessage:AlertMessage?
    var body: some Scene {
        WindowGroup {
            PostsView()
        }
    }
}


class AppDelagate: NSObject, UIApplicationDelegate {
    func applicationDidFinishLaunching(_ application: UIApplication) {
        
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if  configuration.role == .windowApplication  {
            configuration.delegateClass = SceneDelegate.self
        }
        return configuration
    }
}


class SceneDelegate: NSObject, UIWindowSceneDelegate {
    public var window:UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = windowScene.keyWindow
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("Scene did become active")
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        print("Scene will resign active")
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("Scene did enter background")
    }
}
