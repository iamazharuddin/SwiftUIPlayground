//
//  CounterState.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 15/12/25.
//


import Foundation
struct CounterState {
     var isLoading: Bool
     var count: Int
     static let initial: CounterState = .init(isLoading: false, count: 0)
}

