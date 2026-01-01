//
//  PropertyWrappers.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 01/01/26.
//

import Foundation
import SwiftUI
struct URLSessionKey: EnvironmentKey  {
    static var defaultValue: URLSession = .shared
}

extension EnvironmentValues {
    var urlSession: URLSession {
        get {
            self[URLSessionKey.self]
        } set {
            self[URLSessionKey.self] = newValue
        }
    }
}

import SwiftUI
struct PostsView: View {
    @RemoteData(endpoint: .feed) var feed: [Post]
    var body: some View {
        NavigationStack {
            List(feed) { post in
                Text(post.title)
            }
            .navigationTitle("Posts \(feed.count)")
        }
    }
}


@propertyWrapper struct RemoteData: DynamicProperty {
    @Environment(\.urlSession) var urlSession
    @StateObject private var loader = DataLoader()
    var wrappedValue: [Post] {
        loader.loadedData
    }
    private let endpoint:Endpoint
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    func update() {
        if loader.urlSession == nil || loader.endpoint == nil {
            loader.urlSession = urlSession
            loader.endpoint = endpoint
        }
        loader.fetchDataIfNeeded()
    }
}


class DataLoader: ObservableObject {
    var loadedData: [Post] = []
    private var isLoadingData = false
    
    var urlSession: URLSession?
    var endpoint: RemoteData.Endpoint?
    
    init() { }
    
    func fetchDataIfNeeded() {
        guard let urlSession = urlSession, let endpoint = endpoint,
              !isLoadingData && loadedData.isEmpty else {
            return
        }
        
        isLoadingData = true
        let url = URL.for(endpoint)
        urlSession.dataTask(with: url) { data, response, error in
            guard let data = data else {
                /* ... */
                return
            }
            
            DispatchQueue.main.async {
                self.loadedData = try! JSONDecoder()
                    .decode([Post].self, from: data)
                
                self.objectWillChange.send()
            }
            self.isLoadingData = false
    
        }.resume()
    }
}

extension RemoteData {
    enum Endpoint {
        case feed
    }
}

extension URL {
    static func `for`(_ endpoint: RemoteData.Endpoint) -> URL {
        return URL(string: "https://jsonplaceholder.typicode.com/posts")!
    }
}

import Foundation

struct  Post: Codable, Identifiable, Hashable, Equatable {
        let userId: Int
        let id: Int
        let title: String
}

