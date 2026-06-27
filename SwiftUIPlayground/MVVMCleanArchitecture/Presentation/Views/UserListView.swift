//
//  UserListView.swift
//  SwiftUIPlayground
//
//  View - Presentation Layer
//  SwiftUI view that binds to ViewModel
//

import SwiftUI

struct UserListView: View {
    @State private var viewModel: UserListViewModel
    @State private var showingAddUser = false
    @State private var newUserName = ""
    @State private var newUserEmail = ""
    
    init(viewModel: UserListViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.users.isEmpty {
                    ProgressView("Loading users...")
                } else {
                    userList
                }
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddUser = true
                    }
                }
            }
            .task {
                await viewModel.loadUsers()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showingAddUser) {
                addUserSheet
            }
        }
    }
    
    private var userList: some View {
        List {
            ForEach(viewModel.users) { user in
                UserRowView(user: user)
            }
            .onDelete { offsets in
                viewModel.deleteUser(at: offsets)
            }
        }
        .refreshable {
            await viewModel.loadUsers()
        }
    }
    
    private var addUserSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newUserName)
                TextField("Email", text: $newUserEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddUser = false
                        newUserName = ""
                        newUserEmail = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.createUser(name: newUserName, email: newUserEmail)
                            if viewModel.errorMessage == nil {
                                showingAddUser = false
                                newUserName = ""
                                newUserEmail = ""
                            }
                        }
                    }
                    .disabled(newUserName.isEmpty || newUserEmail.isEmpty || viewModel.isLoading)
                }
            }
        }
    }
}

struct UserRowView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.name)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}



