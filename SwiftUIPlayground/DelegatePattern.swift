//
//  DelegatePattern.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 19/10/25.
//

import Foundation

protocol ViewModelDelegate {
    func didDataReceived(_ data: String)
}

class ViewModel {
     var delegate: ViewModelDelegate?
     func fetchData()  {
          DispatchQueue.main.asyncAfter(deadline: .now() + 2){
              self.delegate?.didDataReceived("Hello World")
          }
     }
}

struct  AppUI :  ViewModelDelegate {
        init () {
          let viewModel = ViewModel()
          viewModel.delegate = self
          viewModel.fetchData()
       }
    
       func didDataReceived(_ data: String) {
           print("Data received: \(data)")
       }
}



                                        
