//
//  CounterIntent.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 14/12/25.
//


import Foundation
import Combine
class CounterViewModel: ObservableObject {
    @Published var state: CounterState = .initial
    func send( _ intent: CounterIntent) {
        let (state, effects) =  reducer(state, intent)
        self.state = state
        for effect in effects {
            effect.run(send)
        }
    }
    
    private func reducer( _ state: CounterState, _ intent: CounterIntent) -> (CounterState, [CounterEffect]) {
        var newState = state, effects = [CounterEffect]()
        switch intent {
        case .increment:
            newState.count = clamp(min: 0, max: 10, value: newState.count + 1)
        case .decrement:
            newState.count = clamp(min: 0, max: 10, value: newState.count - 1)
        case .reset:
            newState.count = 0
        case .incrementAfterDelay:
            newState.isLoading = true
            let effect = CounterEffect(run: run)
            effects.append(effect)
       case .didFinishIncrement:
            newState.count = clamp(min: 0, max: 10, value: newState.count + 1)
            newState.isLoading = false
        }
        return (newState, effects)
    }
    
    private func run(send: @escaping (CounterIntent) -> Void)  {
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
             send(.didFinishIncrement)
         }
    }
}



