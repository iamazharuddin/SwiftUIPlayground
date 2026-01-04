//
//  Network.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 04/01/26.
//

import Foundation

enum NetworkError: Error {
    case invalidToken
    case invalidResponse
}

class Network {
    let authManager:AuthManager
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func loadRequest<T:Decodable>( _ urlString: String,  type: T.Type, allowRetry: Bool = true) async throws -> T  {
        let url = URL(string: urlString)!
        let request = try await getAuthorisedRequest(url)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse, response.statusCode == 401 {
            if  allowRetry {
                print("Retrying...")
                 _ = try await authManager.refreshToken()
                return try await loadRequest(urlString, type: type, allowRetry: false)
            }
            throw NetworkError.invalidToken
        }
        return try JSONDecoder().decode(type.self, from: data)
    }
    
    func getAuthorisedRequest( _ url:URL) async throws -> URLRequest {
        var request = URLRequest(url: url)
        let token = try await authManager.validToken()
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}
