//
//  MockUserDataSource.swift
//  SwiftUIPlayground
//
//  Mock Data Source - For testing/demo purposes
//

import Foundation

class MockUserDataSource: UserDataSource {
    private var users: [User] = [
        User(id: "1", name: "John Doe", email: "john@example.com"),
        User(id: "2", name: "Jane Smith", email: "jane@example.com"),
        User(id: "3", name: "Bob Johnson", email: "bob@example.com")
    ]
    
    func fetchUsers() async throws -> [User] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        return users
    }
    
    func fetchUser(id: String) async throws -> User {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        guard let user = users.first(where: { $0.id == id }) else {
            throw UserError.userNotFound
        }
        return user
    }
    
    func createUser(_ user: User) async throws -> User {
        try await Task.sleep(nanoseconds: 500_000_000)
        users.append(user)
        return user
    }
    
    func updateUser(_ user: User) async throws -> User {
        try await Task.sleep(nanoseconds: 500_000_000)
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            throw UserError.userNotFound
        }
        users[index] = user
        return user
    }
    
    func deleteUser(id: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        guard let index = users.firstIndex(where: { $0.id == id }) else {
            throw UserError.userNotFound
        }
        users.remove(at: index)
    }
}

