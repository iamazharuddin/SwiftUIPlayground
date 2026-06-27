//
//  MVVMExampleView.swift
//  SwiftUIPlayground
//
//  Example entry point - Shows how to wire up all layers
//

import SwiftUI

struct MVVMExampleView: View {
    var body: some View {
        // Dependency Injection Setup
        // This is where we wire up all the layers
        
        // 1. Create Data Source (Data Layer)
        let dataSource: UserDataSource = MockUserDataSource()
        
        // 2. Create Repository Implementation (Data Layer)
        let repository: UserRepository = UserRepositoryImpl(dataSource: dataSource)
        
        // 3. Create Use Cases (Domain Layer)
        let fetchUsersUseCase = FetchUsersUseCase(repository: repository)
        let createUserUseCase = CreateUserUseCase(repository: repository)
        
        // 4. Create ViewModel (Presentation Layer)
        let viewModel = UserListViewModel(
            fetchUsersUseCase: fetchUsersUseCase,
            createUserUseCase: createUserUseCase
        )
        
        // 5. Create View (Presentation Layer)
        UserListView(viewModel: viewModel)
    }
}

#Preview {
    MVVMExampleView()
}



