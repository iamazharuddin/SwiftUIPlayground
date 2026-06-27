//
//  KeychainError.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 04/01/26.
//


import Security
import Foundation

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
}

struct KeychainStore {

    private static let service = "com.yourcompany.auth"
    private static let account = "auth_token"

    static func save(_ token: Token) throws {
        let data = try JSONEncoder().encode(token)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = query.merging([
            kSecValueData as String: data
        ]) { $1 }

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    static func load() throws -> Token? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess,
              let data = item as? Data
        else {
            throw KeychainError.unexpectedStatus(status)
        }

        return try JSONDecoder().decode(Token.self, from: data)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
