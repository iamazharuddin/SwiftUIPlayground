//
//  Login.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 04/01/26.
//


import SwiftUI
struct Login:View {
    let loginApi = LoginApi()
    let network = Network(authManager: .shared)
    @State private var profile:Profile?
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    var body: some View {
        NavigationStack {
            if !loggedIn {
                Button(action: {
                    Task {
                        do {
                            _ = try await loginApi.login()
                            loggedIn = true
                        } catch {
                            debugPrint(error)
                        }
                    }
                }, label: {
                    Text("Login")
                })
            }  else {
                Group {
                    if let profile {
                        Text("Profile Detail: \(profile.name)")
                    } else {
                        ProgressView()
                            .tint(.accentColor)
                            .frame(width: 80, height: 80)
                    }
                }
                .onAppear() {
                    Task {
                        do {
                            self.profile = try await network.loadRequest("https://api.escuelajs.co/api/v1/auth/profile", type: Profile.self, allowRetry: true)
                        } catch {
                            debugPrint(error)
                        }
                    }
                }
            }
        }
    }
}

struct Profile:Decodable {
    let id:Int
    let name:String
}
