//
//  ConcurrenycView.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 02/12/25.
//

import SwiftUI
struct ConcurrenycView: View {
    let queue = DispatchQueue(label: "com.example.queue", attributes: .concurrent)
    @State private var counter: Int = 0
    var body: some View {
        Button("Counter \(counter)") {
            queue.sync {
                for i in 0..<100000 {
                    print("\(i)")
                }
            }
            counter += 1
        }
    }
}

#Preview {
    ConcurrenycView()
}
