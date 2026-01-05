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
        observeApplicationState()
    }
    
    func observeApplicationState() {
       NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification, object: nil)
           .sink { [weak self] _ in
               Log.info("willTerminateNotification1")
           }
           .store(in: &cancellables)
       
       NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification, object: nil)
           .sink { [weak self] _ in
               Log.info("didEnterBackgroundNotification")
           }
           .store(in: &cancellables)
       
       NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification, object: nil)
           .sink { [weak self] _ in
              
               
           }
           .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification, object: nil)
            .sink { [weak self] _ in
               
               
            }
            .store(in: &cancellables)
   }
}
