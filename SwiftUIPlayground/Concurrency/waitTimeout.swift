//
//  TaskTimeout.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 23/11/25.
//

import Foundation
import Combine
func waitTimeout<T>(
    seconds: TimeInterval,
    _ work: @escaping () async -> T
) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        group.addTask { await work() }
        group.addTask {
            try? await Task.sleep(for: .seconds(seconds))
            return nil
        }
        let value = await group.next() ?? nil
        group.cancelAll()
        return value
    }
}


