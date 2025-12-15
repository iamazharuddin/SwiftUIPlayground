//
//  CounterView.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 15/12/25.
//

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
