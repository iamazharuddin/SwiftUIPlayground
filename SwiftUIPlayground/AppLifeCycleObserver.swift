//
//  AppLifeCycleObserver.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 08/12/25.
//

import Foundation
import Combine
import UIKit
class AppLifeCycleObserver {
    private var cancellables: Set<AnyCancellable> = []
    init() {

    }
    
    func observeApplicationState() {
       NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification, object: nil)
           .sink { [weak self] _ in
               debugPrint("willTerminateNotification")
           }
           .store(in: &cancellables)
       
       NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification, object: nil)
           .sink { [weak self] _ in
               guard let self = self else { return }
               debugPrint("didEnterBackgroundNotification")
           }
           .store(in: &cancellables)
       
       NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification, object: nil)
           .sink { [weak self] _ in
               guard let self = self else { return }
               debugPrint("willEnterForegroundNotification")
           }
           .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification, object: nil)
            .sink { [weak self] _ in
                guard let self = self else { return }
                debugPrint("didBecomeActiveNotification")
            }
            .store(in: &cancellables)
   }
}
