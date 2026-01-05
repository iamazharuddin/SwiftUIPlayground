//
//  AuthManager.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 02/01/26.
//

import Foundation
struct Token:Identifiable, Codable {
     var id = UUID()
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
     private var refreshTask: Task<Token,Error>?
     func validToken() async throws -> Token {
         if  let refreshTask  {
             return try await refreshTask.value
         }
                  
         if let token = getToken() {
            return token
         }
         return try await refreshToken()
     }
     
     func refreshToken() async throws -> Token {
         if  let task = refreshTask {
             return try await task.value
         }
         let task =  Task { () async throws -> Token in
             guard let url = URL(string: "https://api.escuelajs.co/api/v1/auth/refresh-token") else {
                 throw AuthError.missingToken
             }
             
             var request = URLRequest(url: url)
             request.httpMethod = "POST"
             request.setValue("application/json", forHTTPHeaderField: "Content-Type")
             request.httpBody = try JSONSerialization.data(withJSONObject: ["refreshToken": getToken()?.refreshToken ?? ""])
             let (data, response) = try await URLSession.shared.data(for: request)
             
             // Validate response
             if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode) {
                 throw AuthError.missingToken
             }
             
             let model = try JSONDecoder().decode(Token.self, from: data)
             saveToken(model)
             return model
         }
         refreshTask = task
         
         do {
             let token = try await task.value
             refreshTask = nil // Clean up after success
             return token
         } catch {
             refreshTask = nil // Clean up after error
             throw error
         }
     }
    
     func saveToken(_ token:Token) {
         do {
             try KeychainStore.save(token)
             print("Token saved successfully")
         } catch {
             print(error.localizedDescription)
         }
     }
    
     func getToken() -> Token? {
        do {
            let token = try KeychainStore.load()
            Log.info(token)
            if  token != nil {
                Log.info("Token retrieved successfully")
            }
            return token
        } catch {
            print(error.localizedDescription)
            return nil
        }
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
