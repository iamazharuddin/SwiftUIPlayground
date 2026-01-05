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
    var url: URL? {
        return URL(string: urlString)
    }
    var urlRequest: URLRequest? {
        guard let url = url else { return nil }
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



enum NetworkError: LocalizedError {
    case invalidToken
    case invalidResponse
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid or expired token"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid URL"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

class Network {
    let authManager:AuthManager
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func loadRequest<T:Decodable>( _ endPoint: Endpoint,  type: T.Type, allowRetry: Bool = true) async throws -> T  {
        Log.info(endPoint)
        guard let request = try await getAuthorisedRequest(endPoint) else {
            throw NetworkError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        // Handle 401 Unauthorized with token refresh
        if httpResponse.statusCode == 401 {
            if allowRetry {
                print("Retrying...")
                _ = try await authManager.refreshToken()
                return try await loadRequest(endPoint, type: type, allowRetry: false)
            }
            throw NetworkError.invalidToken
        }
        
        // Validate successful status codes (200-299)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Decode response
        do {
            return try JSONDecoder().decode(type.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func getAuthorisedRequest( _ endpoint:Endpoint) async throws -> URLRequest? {
        guard var request = endpoint.urlRequest else {
            return nil
        }
        if !(endpoint is LoginApiRequest) {
            let token = try await authManager.validToken()
            request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        }
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
