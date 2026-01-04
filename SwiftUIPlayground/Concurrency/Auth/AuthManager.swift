//
//  AuthManager.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 02/01/26.
//

import Foundation
struct Token:Decodable {
     let accessToken: String
     let refreshToken: String
    
     var isValid: Bool {
          true
     }
}

enum AuthError:Error  {
     case missingToken
}

actor AuthManager {
     static let shared = AuthManager()
     private init() {}
     private var currentToken:Token?
     private var refreshTask: Task<Token,Error>?
     func validToken() async throws -> Token {
         if  let refreshTask  {
             return try await refreshTask.value
         }
         
         guard let currentToken = currentToken else {
             throw AuthError.missingToken
         }
         
         if currentToken.isValid {
            return currentToken
         }
         return try await refreshToken()
     }
     
     func refreshToken() async throws -> Token {
         if  let task = refreshTask {
             return try await task.value
         }
         let task =  Task { () async throws -> Token in
             let url = URL(string: "")!
             var request = URLRequest(url: url)
             request.httpMethod = "POST"
             request.setValue("application/json", forHTTPHeaderField: "Content-Type")
             request.httpBody = try JSONSerialization.data(withJSONObject: ["refreshToken": currentToken?.refreshToken ?? ""])
             let (data, _) = try await URLSession.shared.data(for: request)
             return try  JSONDecoder().decode(Token.self, from: data)
         }
         refreshTask = task
         return try await task.value
     }
    
     func saveToken(_ token:Token) {
          self.currentToken = token
     }
}



/*
import Foundation
fileprivate struct Token {
    let validUntil: Date
    let id: UUID
    let value:String = ""
    init(validUntil: Date, id: UUID) {
        self.id = id
        self.validUntil = validUntil
    }
    var isValid: Bool {
        return Bool.random()
    }
}

enum AuthError: Error {
    case missingToken
    case invalidToken
}
actor AuthManager {
    private var currentToken: Token?
    private var refreshTask: Task<Token, Error>?

    fileprivate func validToken() async throws -> Token {
        if let handle = refreshTask {
            return try await handle.value
        }

        guard let token = currentToken else {
            throw AuthError.missingToken
        }

        if token.isValid {
            return token
        }

        return try await refreshToken()
    }

    fileprivate func refreshToken() async throws -> Token {
        if  let refreshTask {
            return try await refreshTask.value
        }
        
        let task = Task { () throws -> Token in
            defer {
                refreshTask = nil
            }
            let tokenExpiresAt = Date().addingTimeInterval(10)
            let newToken = Token(validUntil: tokenExpiresAt, id: UUID())
            currentToken = newToken
            
            return newToken
        }
        refreshTask = task
        return try await task.value
    }
}

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
*/
