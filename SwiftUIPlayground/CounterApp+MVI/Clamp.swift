//
//  Clamp.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 15/12/25.
//


func clamp<T:Comparable>(min:T, max:T, value:T) -> T {
    if value < min {
        return min
    }
    if value > max {
        return max
    }
    return value
}
