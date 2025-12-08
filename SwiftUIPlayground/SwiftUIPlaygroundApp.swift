//
//  SwiftUIPlaygroundApp.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 11/10/25.
//

import SwiftUI
import Combine
@main
struct SwiftUIPlaygroundApp: App {
    @State private var cancellables: Set<AnyCancellable> = []
    let observer = AppLifeCycleObserver()
    var body: some Scene {
        WindowGroup {
            VStack {
                ConcurrenycView()
                Button("Click me") {
                    TaskClosureLifeCycle().incrementValueWithTask()
                }
            }
            .onAppear() {
                observer.observeApplicationState()
            }
        }
    }
}
