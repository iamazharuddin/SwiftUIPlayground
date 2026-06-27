//
//  Login.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 04/01/26.
//


import SwiftUI
class LoginViewModel: ObservableObject {
    let network = Network(authManager: .shared)
    @Published private(set) var profile:Profile?
    @AppStorage("loggedIn") private(set) var loggedIn: Bool = false
    
    @MainActor
    func callProfileApi() async   {
        do {
            let endPoint = ProfileApiEndpoint(urlString: "https://api.escuelajs.co/api/v1/auth/profile", method: "GET")
            profile = try await network.loadRequest(endPoint, type: Profile.self, allowRetry: true)
        } catch {
            Log.info(error)
        }
    }
    
    @MainActor
    func callLoginApi() {
        Task {
            do {
                let jsonData: [String: Any] = [
                    "email": "john@mail.com",
                    "password": "changeme"
                ]
                let endpoint = LoginApiRequest(urlString: "https://api.escuelajs.co/api/v1/auth/login", method: "POST", body: try? JSONSerialization.data(withJSONObject: jsonData))
                let model = try await network.loadRequest(endpoint, type: LoginResponse.self, allowRetry: true)
                await AuthManager.shared.saveToken(Token(accessToken: model.accessToken, refreshToken: model.refreshToken))
                loggedIn = true
            }  catch {
                loggedIn = false 
                Log.info(error)
            }
        }
    }
    
    func logout() {
         loggedIn = false
         KeychainStore.clear()
    }
}

struct Login:View {
    @StateObject private var viewModel: LoginViewModel = .init()
    var body: some View {
        NavigationStack {
            if !viewModel.loggedIn {
                Button(action: {
                    viewModel.callLoginApi()
                }, label: {
                    Text("Login")
                })
            }  else {
                Group {
                    if let profile = viewModel.profile {
                        Text("Profile Detail: \(profile.name)")
                    } else {
                        ProgressView()
                            .tint(.accentColor)
                            .frame(width: 80, height: 80)
                    }
                }
                .navigationTitle(Text("Profile"))
                .toolbar(content: {
                    if viewModel.loggedIn {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Logout") {
                                viewModel.logout()
                            }
                        }
                    }
                })
                .task {
                   await viewModel.callProfileApi()
                }
            }
        }
    }
}

struct Profile:Decodable {
    let id:Int
    let name:String
}
