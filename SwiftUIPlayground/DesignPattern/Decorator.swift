//
//  Decorator.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 15/04/26.
//

import Foundation
protocol UserLoader {
    func fetchUser(completion: @escaping (Result<User, Error>) -> Void)
}

final class APIUserLoader: UserLoader {
    func fetchUser(completion: @escaping (Result<User, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            completion(.success(User(name: "", email: "")))
        }
    }
}

final class MainThreadApiDecorator : UserLoader {
    let userLoader: UserLoader = APIUserLoader()
    
    func fetchUser(completion: @escaping (Result<User, Error>) -> Void) {
        self.userLoader.fetchUser { res in
            DispatchQueue.main.async {
                completion(res)
            }
        }
    }
}

class DecoratorViewModel {
    let loader: UserLoader
    init (userLoader: UserLoader) {
        self.loader = userLoader
    }
    
    func run() {
        loader.fetchUser { res in
            print(res)
        }
    }
}

