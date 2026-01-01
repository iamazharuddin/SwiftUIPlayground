//
//  EventBuffer.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 25/12/25.
//


import Foundation

final class EventBuffer<Event> {
    private var events: [Event] = []
    private let queue = DispatchQueue(
        label: "com.example.eventbuffer",
        attributes: .concurrent
    )

    // Add is concurrent & fast
    func add(_ event: Event) {
        queue.async(flags: .barrier) {
            self.events.append(event)
        }
    }

    // Flush is exclusive
    func flush(_ handler: @escaping ([Event]) -> Void) {
        queue.async() {
            guard !self.events.isEmpty else { return }

            let snapshot = self.events
            print("Snapshot 1: \(snapshot)")
            self.events.removeAll()
            print("Snapshot 2: \(snapshot)")
            handler(snapshot)
        }
    }
    
    func printAllEvents() {
        queue.sync {
            print(self.events)
        }
    }
}

let buffer = EventBuffer<String>()
func callSomeCode() {

    DispatchQueue.global().async {
        for i in 0..<100 {
            buffer.add("Event \(i+1)")
        }
        
        buffer.printAllEvents()
    }
    


    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2.0) {
        var allEvents: [String] = []
        buffer.flush { events in
            allEvents.append(contentsOf: events)
            print("allEvents: \(allEvents)")
        }
    }
}








