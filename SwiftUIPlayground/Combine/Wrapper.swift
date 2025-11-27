//
//  Wrapper.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 23/11/25.
//


import UIKit
import Combine
import Foundation


fileprivate struct Wrapper<Output> {
    var output: Output
    var isGenuine: Bool
}

fileprivate struct ScanState<Output> {
    var output: Output?
    var hasSeenGenuine: Bool = false
}


extension Publisher {
    func defaulting<S: Scheduler>(
        to defaultOutput: Output,
        after timeout: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> some Publisher<Output, Failure> {
        let genuine = self
            .map { Wrapper(output: $0, isGenuine: true) }

        let defaulted = Just(Wrapper(
            output: defaultOutput,
            isGenuine: false
        ))
            .setFailureType(to: Failure.self)
            .delay(for: timeout, scheduler: scheduler)

        return genuine.merge(with: defaulted)
            .scan(ScanState<Output>()) { state, wrapper in
                if state.hasSeenGenuine && !wrapper.isGenuine {
                    return ScanState(output: nil, hasSeenGenuine: true)
                } else {
                    return ScanState(
                        output: wrapper.output,
                        hasSeenGenuine: wrapper.isGenuine || state.hasSeenGenuine
                    )
                }
            }
            .compactMap { $0.output }
    }
}


func runTest() -> AnyCancellable {
     let apiCall1 = Just("answer1").delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
     let apiCall2 = Just("answer2").delay(for: .milliseconds(400), scheduler: DispatchQueue.main)
     let apiCall3 = Just("answer3").delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
     let apiCall4 = Just("answer4").delay(for: .seconds(2), scheduler: DispatchQueue.main)
     
     let defaultedCall4 = apiCall4.defaulting(to: "default", after: .milliseconds(1000), scheduler: DispatchQueue.main)
     let combo =  Publishers.CombineLatest4(apiCall1, apiCall2, apiCall3, defaultedCall4)

     let ticket = combo.sink { print($0) }
     return ticket
}



