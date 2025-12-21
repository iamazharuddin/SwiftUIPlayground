//
//  UserDataSource.swift
//  SwiftUIPlayground
//
//  Data Source Protocol - Can be implemented for API, Database, Cache, etc.
//

import Foundation

protocol UserDataSource {
    func fetchUsers() async throws -> [User]
    func fetchUser(id: String) async throws -> User
    func createUser(_ user: User) async throws -> User
    func updateUser(_ user: User) async throws -> User
    func deleteUser(id: String) async throws
}


