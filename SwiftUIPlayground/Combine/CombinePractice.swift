//
//  Practice.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 25/12/25.
//
//
import Foundation
import Combine
import SwiftUI
struct CombinePracticeView: View {
     @StateObject private var vm = CombinePractice()
     var body: some View {
         Button(vm.title) {
//             vm.title = "Changed! \(Int.random(in: 0..<100))"
             vm.send("Changed! \(Int.random(in: 0..<100))")
         }
    }
}

class CombinePractice:ObservableObject {
    @Published var title: String = "Hello, World!"
    private let titleSubject = CurrentValueSubject<String, Never>("First")
    init() {
//        $title
//            .receive(subscriber: TitleSubscriber())
        titleSubject.receive(subscriber: TitleSubscriber())
    }
    
    func send( _ input: String) {
         titleSubject.send(input)
    }
}


class TitleSubscriber: Subscriber  {
    typealias Input = String
    typealias Failure = Never
    func receive(_ input: Input) -> Subscribers.Demand {
        print("Received: \(input)")
        return .max(1)
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("Completion: \(completion)")
    }
    
    func receive(subscription: Subscription) {
         print( "Subscription: \(subscription)")
        subscription.request(.max(1))
    }
}
