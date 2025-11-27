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
    var body: some Scene {
        WindowGroup {
//            SlideToConfirm()
//            ChipsView()
//            CardSkeletonView()
//            InternetConnectivityWrapperView()
//            FullScreenSheetContainerView()
//            PlayGround()
//            StarView()
//              CurvedAnimation()
//            CustomCurve()
//            PlayGround()
//            SpotifyHome()
//            CustomListCallingView()
            MYContent()
                .onAppear() {
                    runTest()
                        .store(in: &cancellables)
                }
        }
    }
}
