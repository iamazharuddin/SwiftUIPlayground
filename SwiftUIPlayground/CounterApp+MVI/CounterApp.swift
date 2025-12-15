//
//  CounterIntent.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 14/12/25.
//


import Foundation
import Combine

struct CounterEffect {
    let id = UUID()
    let run: (@escaping (CounterIntent) -> Void) -> Void
}


enum CounterIntent {
     case increment, decrement, reset, incrementAfterDelay, didFinishIncrement
}

class CounterViewModel: ObservableObject {
    @Published var state: CounterState = .initial
    func send( _ intent: CounterIntent) {
        let (state, effects) =  reducer(state, intent)
        self.state = state
        for effect in effects {
            effect.run { action in
                self.send(action)
            }
        }
    }
    
    private func reducer( _ state: CounterState, _ intent: CounterIntent) -> (CounterState, [CounterEffect]) {
        switch intent {
        case .increment:
            return (.init(isLoading: false, count: state.count + 1), [])
        case .decrement:
            return (.init(isLoading: false, count: state.count - 1), [])
        case .reset:
            return (.init(isLoading: false, count: 0), [])
        case .incrementAfterDelay:
            let updatedState = CounterState(isLoading: true, count: state.count)
            let effect = CounterEffect(run: run)
           return (updatedState, [effect])
       case .didFinishIncrement:
            return (.init(isLoading: false, count: state.count + 1), [])
        }
    }
    
    private func run(callback: @escaping (CounterIntent) -> Void)  {
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
             callback(.didFinishIncrement)
         }
    }
}


struct CounterState {
     var isLoading: Bool
     var count: Int
     static let initial: CounterState = .init(isLoading: false, count: 0)
}


import SwiftUI
struct CounterView: View {
     @StateObject  private var viewModel: CounterViewModel = .init()
     var body: some View {
         VStack(spacing: 24) {
             Text("\(viewModel.state.count)")
             
             Button {
                 self.viewModel.send(.incrementAfterDelay)
             } label: {
                 Text("Increment")
                     .font(.headline)
                     .fontWeight(.bold)
                     .font(.system(size: 20, weight: .bold))
                     .foregroundStyle(Color.white)
                     .padding(10)
                     .background(Color.gray, in: .rect(cornerRadius: 8))
             }
             .disabled(viewModel.state.isLoading)

             Button {
                 self.viewModel.send(.decrement)
             } label: {
                 Text("Decrement")
                     .font(.headline)
                     .fontWeight(.bold)
                     .font(.system(size: 20, weight: .bold))
                     .foregroundStyle(.white)
                     .padding(10)
                     .background(Color.gray, in: .rect(cornerRadius: 8))
             }
             
             Button {
                 self.viewModel.send(.reset)
             } label: {
                 Text("Reset")
                     .font(.headline)
                     .font(.system(size: 20, weight: .bold))
                     .foregroundStyle(.red)
                     .padding(10)
                     .background(Color.gray.opacity(0.5), in: .rect(cornerRadius: 8))
             }
         }
         .overlay {
             ProgressView()
                 .tint(.blue)
                 .opacity(self.viewModel.state.isLoading ? 1 : 0)
         }
    }
}

#Preview {
    CounterView()
}

