//
//  User.swift
//  SwiftUIPlayground
//
//  Domain Entity - Core business model
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let email: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, email: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
    }
}



