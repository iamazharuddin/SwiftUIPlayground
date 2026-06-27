//
//  Observer.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 15/04/26.
//

import Foundation


protocol Observable: AnyObject {
    func register(_ observer: Observer, _ event: String)
    func unregister(_ observer: Observer, _ event: String)
    func notify(_ event: String, data: Any?)
}

protocol Observer: AnyObject {
    func receive(_ event: String, data: Any?)
}


final class CustomNotificationCenter: Observable {
    static let shared = CustomNotificationCenter()
    
    private init() { }
    
    private lazy var observers: [String : [Observer]] = .init()
    
    func register(_ observer: Observer, _ event: String) {
        guard !(observers[event]?.contains(where: { $0 === observer }) ?? false) else { return }
        
        if observers[event] != nil {
            observers[event]?.append(observer)
            return
        }
        observers[event] = [observer]
    }
    
    func unregister(_ observer: Observer, _ event: String) {
        observers[event]?.removeAll(where: { $0 === observer })
    }
    
    func notify(_ event: String, data: Any?) {
        guard let observers = observers[event] else {
            return
        }
        for observer in observers {
            observer.receive(event, data: data)
        }
    }
}


class Sender {
    func sendEvent(_ event: String, _ data: Any) {
        CustomNotificationCenter.shared.notify(event, data: data)
    }
}

class Observer1: Observer {
    init() {
        CustomNotificationCenter.shared.register(self, "Event")
    }
    
    func receive(_ event: String, data: Any?) {
        if event == "Event", let data = data as? Int {
            print("Observer 1 received \(data)")
        }
    }
}

class Observer2: Observer {
    init() {
        CustomNotificationCenter.shared.register(self, "Event")
    }
    
    func receive(_ event: String, data: Any?) {
        if event == "Event", let data = data as? Int {
            print("Observer 2 received \(data)")
        }
    }
}


class Runner  {
    static  func run() {
        let sender = Sender()
        let observer1 = Observer1()
        let observer2 = Observer2()
        sender.sendEvent("Event", 10)
        
    }
}
