//
//  CounterFeatureTests.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 15/12/25.
//


import XCTest
import ComposableArchitecture
@testable import SwiftUIPlayground

@MainActor
final class CounterFeatureTests: XCTestCase {

    func testAsyncIncrement() async {

        let store = TestStore(
            initialState: CounterFeature.State(),
            reducer: { CounterFeature() }
        )

        // 1️⃣ User taps increment
        await store.send(.incrementButtonTapped) {
            $0.isLoading = true
        }

        // 2️⃣ Effect completes after delay
        await store.receive(.incrementResponse(1)) {
            $0.isLoading = false
            $0.count = 1
        }

    }
}
