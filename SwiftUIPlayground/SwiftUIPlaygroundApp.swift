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
    @State  private var progress: Double = 0
    @State private var status:DownloadState = .none
     
    let downloadService = DownloadService.shared
    @State private var cancellables: Set<AnyCancellable> = []
    let observer = AppLifeCycleObserver()
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("\(progress*100) % completed")
                if case .downloaded = status {
                    Text("Download Completed")
                        .font(.headline)
                        .bold()
                } else {
                    Button("Click me") {
                        downloadService.startDownload("https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf")
                    }
                }
            }
            .onReceive(downloadService.downloadPublisher.receive(on: RunLoop.main)) { downloadInfo in
                if case let .downloading(progress) = downloadInfo.downloadState {
                    self.progress = progress
                }
                
                self.status = downloadInfo.downloadState
            }
        }
    }
}
