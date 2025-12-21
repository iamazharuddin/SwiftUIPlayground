//
//  Counter.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 20/12/25.
//

// https://medium.com/@dmytro_chumakov/dispatchsemaphore-in-swift-1b03a90ff94f
import Foundation

class Counter {
    let semaphore = DispatchSemaphore(value: 1)
    
    var counter = 0
    
    func task() {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        Thread.sleep(forTimeInterval: 1.0)
        counter += 1
        print("Counter Value: \(counter)")
    }
    
    
    func run() {
        let queue = DispatchQueue(label: "com.example.queue", attributes: .concurrent)
        queue.async(execute: task)
        queue.async(execute: task)
    }
    
}


class MutableArray {
      let semaphore = DispatchSemaphore(value: 2)
      var sharedArray: [Int] = []
    
     func addToArray() {
         semaphore.wait()
         defer {
             semaphore.signal()
         }
         print("Thread \(Thread.current) added values to array")
         for value in 1...5 {
             print( "Added \(value) to array")
             sharedArray.append(value)
         }
         Thread.sleep(forTimeInterval: 1)
         print("\(#function): \(sharedArray)")
     }
    
     func removeFromArray( ) {
         semaphore.wait()
         defer {
             semaphore.signal()
         }
         print( "Thread \(Thread.current) removed values from array")
         for removeValue in 1...5 {
             if let index = sharedArray.firstIndex(of: removeValue) {
                 print("Removed \(removeValue) at index \(index)")
                 sharedArray.remove(at: index)
             }
         }
         Thread.sleep(forTimeInterval: 1)
         print("\(#function): \(sharedArray)")
     }
    

}

//Counter().run()
let test = {
    let queue = DispatchQueue(label: "com.example.queue", attributes: .concurrent)
    func run() {
        var mutableArray = MutableArray()
        queue.async {
            mutableArray.addToArray()
        }
        queue.async {
            mutableArray.removeFromArray()
        }
    }
    
    run()
}
// DispatchSemaphore is synchronisation mechanism to control the number threads that can access a shared resource
// Used to manage thread execution that can access the shared resource
