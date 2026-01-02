//
//  AuthManager.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 02/01/26.
//

import Foundation
struct Token {
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

    func validToken() async throws -> Token {
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

    func refreshToken() async throws -> Token {
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

