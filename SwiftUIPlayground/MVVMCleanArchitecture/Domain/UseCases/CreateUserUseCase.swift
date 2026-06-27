//
//  CreateUserUseCase.swift
//  SwiftUIPlayground
//
//  Use Case - Business logic for creating users
//

import Foundation

struct CreateUserUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(name: String, email: String) async throws -> User {
        // Business rule: Validate email format
        guard email.contains("@") else {
            throw UserError.invalidEmail
        }
        
        // Business rule: Name must not be empty
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw UserError.invalidName
        }
        
        let user = User(name: name, email: email)
        return try await repository.createUser(user)
    }
}

enum UserError: LocalizedError {
    case invalidEmail
    case invalidName
    case userNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Invalid email format"
        case .invalidName:
            return "Name cannot be empty"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network error occurred"
        }
    }
}



