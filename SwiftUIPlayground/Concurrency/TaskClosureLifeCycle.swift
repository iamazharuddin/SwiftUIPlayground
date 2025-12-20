//
//  TaskClosureLifeCycle.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 03/12/25.
//

import Foundation
class TaskClosureLifeCycle  {
      private var value:Int = 0
    init() {
        debugPrint("Init")
    }
    deinit {
        debugPrint("Deinit")
    }
     func incrementValueWithTask() {
         Task {
             self.value += 1
             try? await Task.sleep(for: .seconds(2))
             debugPrint("Value incremented to \(self.value)")
         }
     }
}


class CreateRetainCycle {
    private var value:Int = 0
    private var completionHandler: (() -> Void)?
    init () {
        debugPrint("Init")
    }
    
    deinit {
        debugPrint("Deinit 💥")
    }
    
    
    func   incrementWithRetainCycle() {
            completionHandler  =  { [weak self] in
                self?.value += 1
                debugPrint("Value Incremented to \(self?.value)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.completionHandler?()
            }
    }
}

