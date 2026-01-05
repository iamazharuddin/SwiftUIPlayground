//
//  Network.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 04/01/26.
//

import Foundation
protocol Endpoint {
    var urlString: String { get }
    var method: String { get }
    var headers: [String: String] { get }
    var body: Data? { get }
}

extension Endpoint {
    var headers: [String: String] {
        return [:]
    }
    var body: Data? {
        return nil
    }
    var url: URL { URL(string: urlString)! }
    var urlRequest: URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body
        return request
    }
}

struct ProfileApiEndpoint : Endpoint {
    var urlString: String = "https://jsonplaceholder.typicode.com/users"
    var method: String = "GET"
}



enum NetworkError: Error {
    case invalidToken
    case invalidResponse
}

class Network {
    let authManager:AuthManager
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func loadRequest<T:Decodable>( _ endPoint: Endpoint,  type: T.Type, allowRetry: Bool = true) async throws -> T  {
        let request = try await getAuthorisedRequest(endPoint)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse, response.statusCode == 401 {
            if  allowRetry {
                print("Retrying...")
                _ = try await authManager.refreshToken()
                return try await loadRequest(endPoint, type: type, allowRetry: false)
            }
            throw NetworkError.invalidToken
        }
        return try JSONDecoder().decode(type.self, from: data)
    }
    
    func getAuthorisedRequest( _ endpoint:Endpoint) async throws -> URLRequest {
        var request = endpoint.urlRequest
        request.httpBody = endpoint.body
        let token = try await authManager.validToken()
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
