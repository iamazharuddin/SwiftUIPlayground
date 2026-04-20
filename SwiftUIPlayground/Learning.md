//
//  Learning.md
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 18/04/26.
//


loops: performance, crashes, memory, UIKit mechanics, patterns, architecture, and leadership-style prompts. Use as a checklist, not a script.

---
## Table of contents
1.Laggy UITableView and list performance
  Lag in UITableView usually happens when too much work is being done during scrolling on the main thread. I first check cell reuse, image loading, height calculation, Auto Layout cost, and whether expensive formatting or state computation is happening inside cellForRowAt. Then I use Instruments like Time Profiler and Core Animation to find the bottleneck and move expensive work off the main thread or cache it.
2.EXC_BAD_ACCESS and crash classification
3.Background crashes 
5.Memory leaks and detection
6.Design patterns 
7.Clean Architecture
11.Communication and collaboration
12.Library vs Framework
14.Data Races 
17.Cacheing Staregy 
18.What to do if app is getting crash after release. What are the options 
    Pause phased rollout if you are using phased release.
    Turn off the broken feature with remote config / backend kill switch, if possible.
    Remove app from sale temporarily for new users if the issue is severe.
    Ship a hotfix as a new version. Apple says this is the proper path instead of rollback.
4.Data passing patterns and UIResponder

import Foundation

class A {
    private  var value: Int  = 0
    private let serialQueue = DispatchQueue(label: "com.example.A.serialQueue")
    
    func getValue() -> Int {
        var myValue: Int = 0
        // main thread
        serialQueue.sync {
            // block 1 => some random thread from thread pool
            serialQueue.sync {
                //  block 1 //
                myValue =   self.value
            }
        }
        return myValue
    }
    
    func setValue(_ value: Int) {
         serialQueue.async(flags: .barrier) {
            self.value = value
         }
    }
}


let a = A()
a.setValue(10)
print(a.getValue())

Deadlock: Since serialQueue is a serial queue, it can only execute one task at a time. So, when the first sync block starts executing, it blocks the main thread, waiting for the task inside serialQueue.sync { ... } to finish. However, this inner sync block is also waiting to be executed by the same serial queue which is already blocked, creating a deadlock.

/*
 
 UITextField -> UIView ->  UIResponder -> NSObject
 
 Task  {
   let a  = await api1()
   let b =  await ferchFromDB()
   let c =  await api2()
 
    
 }
 
 Task {
     Task {
       
     }
 }
 
 init()
 loadView
 ViewDidLoad
 ViewWillAppear
 ViewDidAppear
 ViewWillLayoutSubView
 ViewDidlayloutSubViews
 
 
 ViewWillDisAppear
 ViewDidDisAppear
 Deinit
 
 
 
 */

import UIKit
class ViewController: UIViewController {
    override func viewDidLoad() {
             super.viewDidLoad()
        
            
    }
    
    override func viewIsAppearing(_ animated: Bool) {
            //
    }
}

/*
 
 App Launch -> didFinidhLaunc
 
 
 Active <-> InActive  -> Bg State
 
 Not Running -> App is
 Active -> Code is executing. User
 InActive -> Execution gets interrupted
 Bg State -> Receiving events -> 30
 Suspended -> Not Receiving events
 
 
 
 
Crash -
  Firebase Crashlytics
  
  exe bad_access
   
 
 Swift - 9
 SwiftUI - 9
 UI - 7
 iOS - 9
 UITabView
     - laggy
  
 
 
 URLSession
     URLCache
 

  
 
 Crash -
   
 I will tracking
 
 SnowPlow -> Kibana
          -> Redshift
 
 Adjust -> Install & Revenus
 Moengage -> Notification, SMS, EMail
 
 Firabse Analytics, Firebase Crashlytics
 
*/

---
