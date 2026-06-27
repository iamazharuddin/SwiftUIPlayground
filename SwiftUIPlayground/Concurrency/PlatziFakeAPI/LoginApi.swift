//
//  LoginApi.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 03/01/26.
//

/*
 POST https://api.escuelajs.co/api/v1/auth/login
 Content-Type: application/json
 
 {
 "email": "john@mail.com",
 "password": "changeme"
 }
 */
import Foundation
struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

struct  LoginApiRequest: Endpoint {
    var urlString: String
    var method: String
    var body: Data?
}

/*
class LoginApi {
    private let authManager: AuthManager
    init(authManager: AuthManager = .shared) { self.authManager = authManager }
    func login() async throws -> LoginResponse {
        let url = URL(string: "https://api.escuelajs.co/api/v1/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let jsonData: [String: Any] = [
            "email": "john@mail.com",
            "password": "changeme"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonData, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let result: (Data, URLResponse) = try await URLSession.shared.data(for: request)
            Log.info(String(data: result.0, encoding: .utf8)!)
            
            let model = try JSONDecoder().decode(LoginResponse.self, from: result.0)
            Log.info(model)
            await authManager.saveToken(Token(accessToken: model.accessToken, refreshToken: model.refreshToken))
            
            return model
        } catch {
            Log.info(error.localizedDescription)
            throw error
        }
    }
    
    /*
     GET https://api.escuelajs.co/api/v1/auth/profile
     Authorization: Bearer {your_access_token}
     */
}



/*
 
 {
 "id": 1,
 "email": "john@mail.com",
 "password": "changeme",
 "name": "Jhon",
 "role": "customer",
 "avatar": "https://api.lorem.space/image/face?w=640&h=480&r=867"
 }
 */
*/
