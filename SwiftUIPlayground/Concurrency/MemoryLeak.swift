//
//  MemoryLeak.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 02/12/25.
//

class MemoryLeak {
    var number = 0
    
    init() {
        debugPrint("MemoryLeak init")
        runTask()
    }
    
    deinit {
        debugPrint("MemoryLeak deinit")
    }
    
    func runTask() {
        Task { [weak self] in
            
            guard let self = self else { return }
            
            try? await Task.sleep(for: .seconds(30))
            
            debugPrint(self.number)
             
        }
    }
}
