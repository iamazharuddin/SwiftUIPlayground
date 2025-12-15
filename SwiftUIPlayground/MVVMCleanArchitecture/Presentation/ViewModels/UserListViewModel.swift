//
//  UserListViewModel.swift
//  SwiftUIPlayground
//
//  ViewModel - Presentation Layer
//  Transforms Domain data for View consumption
//

import Foundation
import Observation

@Observable
class UserListViewModel {
    var users: [User] = []
    var isLoading = false
    var errorMessage: String?
    
    private let fetchUsersUseCase: FetchUsersUseCase
    private let createUserUseCase: CreateUserUseCase
    
    init(
        fetchUsersUseCase: FetchUsersUseCase,
        createUserUseCase: CreateUserUseCase
    ) {
        self.fetchUsersUseCase = fetchUsersUseCase
        self.createUserUseCase = createUserUseCase
    }
    
    @MainActor
    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            users = try await fetchUsersUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func createUser(name: String, email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newUser = try await createUserUseCase.execute(name: name, email: email)
            users.append(newUser)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func deleteUser(at offsets: IndexSet) {
        // In a real app, you'd call a delete use case here
        users.remove(atOffsets: offsets)
    }
}


