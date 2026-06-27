//
//  CounterObservable.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 22/02/26.
//

import SwiftUI

struct CounterObservable: View {
    // @Observable → use @State
    @State private var observableVM = CounterObservableViewModel()
    // ObservableObject → use @StateObject
    @StateObject private var observableObjectVM = CounterObservableObjectViewModel()

    var body: some View {
        VStack(spacing: 24) {
            // --- @Observable (iOS 17+) ---
            Text("Count: \(observableVM.count)")
                .onTapGesture { observableVM.increment() }
            Text("↑ @Observable + @State").font(.caption)

            Divider()

            // --- ObservableObject (classic) ---
            Text("Count: \(observableObjectVM.count)")
                .onTapGesture { observableObjectVM.increment() }
            Text("↑ ObservableObject + @StateObject").font(.caption)
        }
        .padding()
    }
}

#Preview {
    CounterObservable()
}

// MARK: - @Observable (Swift Observation): plain class, plain var, use @State in View
@Observable
class CounterObservableViewModel {
    var count: Int = 0
    func increment() { count += 1 }
}

// MARK: - ObservableObject (classic): protocol, @Published var, use @StateObject in View
private class CounterObservableObjectViewModel: ObservableObject {
    @Published var count: Int = 0
    func increment() { count += 1 }
}
