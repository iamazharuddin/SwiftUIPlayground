//
//  CounterEffect.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 15/12/25.
//

import Foundation
struct CounterEffect {
    let id = UUID()
    let run: (@escaping (CounterIntent) -> Void) -> Void
}


enum CounterIntent {
     case increment, decrement, reset, incrementAfterDelay, didFinishIncrement
}
