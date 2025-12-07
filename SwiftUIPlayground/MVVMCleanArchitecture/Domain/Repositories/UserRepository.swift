//
//  UserRepository.swift
//  SwiftUIPlayground
//
//  Repository Protocol - Domain Layer defines the interface
//

import Foundation

protocol UserRepository {
    func fetchUsers() async throws -> [User]
    func fetchUser(id: String) async throws -> User
    func createUser(_ user: User) async throws -> User
    func updateUser(_ user: User) async throws -> User
    func deleteUser(id: String) async throws
}

