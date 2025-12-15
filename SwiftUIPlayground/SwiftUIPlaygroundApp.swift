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
    let downloadService = DownloadService.shared
    @State private var cancellables: Set<AnyCancellable> = []
    let observer = AppLifeCycleObserver()
    
    let urlString = "https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf"
    
    @State private var alertMessage:AlertMessage?
    var body: some Scene {
        WindowGroup {
//            CustomVideoPlayer()
            CounterView()
        }
    }
}

