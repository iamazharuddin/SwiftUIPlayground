//
//  UserRepositoryImpl.swift
//  SwiftUIPlayground
//
//  Repository Implementation - Data Layer
//

import Foundation

class UserRepositoryImpl: UserRepository {
    private let dataSource: UserDataSource
    
    init(dataSource: UserDataSource) {
        self.dataSource = dataSource
    }
    
    func fetchUsers() async throws -> [User] {
        return try await dataSource.fetchUsers()
    }
    
    func fetchUser(id: String) async throws -> User {
        return try await dataSource.fetchUser(id: id)
    }
    
    func createUser(_ user: User) async throws -> User {
        return try await dataSource.createUser(user)
    }
    
    func updateUser(_ user: User) async throws -> User {
        return try await dataSource.updateUser(user)
    }
    
    func deleteUser(id: String) async throws {
        try await dataSource.deleteUser(id: id)
    }
}


