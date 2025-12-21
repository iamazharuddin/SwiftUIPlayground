//
//  FeedLoader.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 21/12/25.
//


import Foundation
import UIKit

protocol FeedLoader {
    func load(completion: @escaping ([String]) -> Void)
}

class FeedLoadViewController: UIViewController {
    var feeLoader: FeedLoader!
    convenience init(feedLoader:  FeedLoader) {
        self.init()
        self.feeLoader = feedLoader
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemTeal
        feeLoader.load(completion: completion)
    }
    
    func completion(_ fee: [String]) {
         print("Fee: \(fee)")
    }
}


class RemoteFeedLoader : FeedLoader {
    func load(completion: @escaping ([String]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(["100", "200", "300"])
        }
    }
}

class LocalFeedLoader : FeedLoader {
    func load(completion: @escaping ([String]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(["100", "200", "300"])
        }
    }
}

//
//let controller = FeedLoadViewController(feedLoader: LocalFeedLoader())
//PlaygroundPage.current.liveView = controller
