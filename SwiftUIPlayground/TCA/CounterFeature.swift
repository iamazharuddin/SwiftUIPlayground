//
//  CounterFeature.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 15/12/25.
//


import SwiftUI
import ComposableArchitecture

@Reducer
struct CounterFeature {
    
    @ObservableState
    struct State: Equatable {
        var count: Int = 0
        var isLoading: Bool = false
    }
    
    
    enum Action {
        case incrementButtonTapped
        case incrementResponse(Int)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .incrementButtonTapped:
                state.isLoading = true
                
                return .run { send in
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    await send(.incrementResponse(1))
                }
                
            case .incrementResponse(let value):
                state.isLoading = false
                state.count += value
                return .none
            }
        }
    }
}

import SwiftUI

struct CounterViewTCA: View {

    let store: StoreOf<CounterFeature>

    var body: some View {
        VStack(spacing: 20) {

            Text("Count: \(store.count)")
                .font(.largeTitle)

            if store.isLoading {
                ProgressView()
            }

            Button("Increment (Async)") {
                store.send(.incrementButtonTapped)
            }
            .disabled(store.isLoading)
        }
        .padding()
    }
}
