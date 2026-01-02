//
//  Networking.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 02/01/26.
//

import Foundation
class Networking {

    let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func loadAuthorized<T: Decodable>(_ url: URL, allowRetry: Bool = true) async throws -> T {
        let request = try await authorizedRequest(from: url)
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode == 401 {
            if allowRetry {
                 _ = try await authManager.refreshToken()
                return try await loadAuthorized(url, allowRetry: false)
            }
            
            throw AuthError.invalidToken
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(T.self, from: data)

        return response
    }
    


    private func authorizedRequest(from url: URL) async throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        let token = try await authManager.validToken()
        urlRequest.setValue("Bearer \(token.value)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
}
