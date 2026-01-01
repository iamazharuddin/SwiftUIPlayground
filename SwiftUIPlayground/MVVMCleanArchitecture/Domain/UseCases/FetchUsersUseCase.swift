//
//  FetchUsersUseCase.swift
//  SwiftUIPlayground
//
//  Use Case - Encapsulates business logic
//

import Foundation

struct FetchUsersUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [User] {
        return try await repository.fetchUsers()
    }
}



