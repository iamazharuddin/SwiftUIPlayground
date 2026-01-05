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
        Log.info("Init")
    }
    deinit {
        Log.info("Deinit")
    }
     func incrementValueWithTask() {
         Task {
             self.value += 1
             try? await Task.sleep(for: .seconds(2))
             Log.info("Value incremented to \(self.value)")
         }
     }
}


class CreateRetainCycle {
    private var value:Int = 0
    private var completionHandler: (() -> Void)?
    init () {
        Log.info("Init")
    }
    
    deinit {
        Log.info("Deinit 💥")
    }
    
    
    func   incrementWithRetainCycle() {
            completionHandler  =  { [weak self] in
                self?.value += 1
                Log.info("Value Incremented to \(self?.value)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.completionHandler?()
            }
    }
}

