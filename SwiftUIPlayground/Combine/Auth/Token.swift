//
//  Token.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 03/01/26.
//

import Foundation
import Combine
struct CombineToken: Decodable {
  let isValid: Bool
}

fileprivate struct Response: Decodable {
  let message: String
}

fileprivate enum ServiceErrorMessage: String, Decodable, Error {
  case invalidToken = "invalid_token"
}

fileprivate struct ServiceError: Decodable, Error {
  let errors: [ServiceErrorMessage]
}

protocol NetworkSession: AnyObject {
    func publisher(for url: URL, token: CombineToken?) -> AnyPublisher<Data, Error>
}

class MockNetworkSession: NetworkSession {
  func publisher(for url: URL, token: CombineToken? = nil) -> AnyPublisher<Data, Error> {
    let statusCode: Int
    let data: Data

    if url.absoluteString == "https://donnys-app.com/token/refresh" {
      print("fake token refresh")
      data = """
      {
        "isValid": true
      }
      """.data(using: .utf8)!
      statusCode = 200
    } else {
      if let token = token, token.isValid {
        print("success response")
        data = """
        {
          "message": "success!"
        }
        """.data(using: .utf8)!
        statusCode = 200
      } else {
        print("not authenticated response")
        data = """
        {
          "errors": ["invalid_token"]
        }
        """.data(using: .utf8)!
        statusCode = 401
      }
    }

    let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!

    // Use Deferred future to fake a network call
    return Deferred {
      Future { promise in
        DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
          promise(.success((data: data, response: response)))
        })
      }
    }
    .setFailureType(to: URLError.self)
    .tryMap({ result in
      guard let httpResponse = result.response as? HTTPURLResponse,
            httpResponse.statusCode == 200 else {

        let error = try JSONDecoder().decode(ServiceError.self, from: result.data)
        throw error
      }

      return result.data
    })
    .eraseToAnyPublisher()
  }
}


extension URLSession: NetworkSession {
  func publisher(for url: URL, token: CombineToken?) -> AnyPublisher<Data, Error> {
    var request = URLRequest(url: url)
    if let token = token {
      request.setValue("Bearer <access token>", forHTTPHeaderField: "Authentication")
    }

    return dataTaskPublisher(for: request)
      .tryMap({ result in
        guard let httpResponse = result.response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {

          let error = try JSONDecoder().decode(ServiceError.self, from: result.data)
          throw error
        }

        return result.data
      })
      .eraseToAnyPublisher()
  }
}

struct NetworkManager {
    private let session: NetworkSession
    private let authenticator: Authenticator

    init(session: NetworkSession = URLSession.shared) {
      self.session = session
      self.authenticator = Authenticator(session: session)
    }

   fileprivate func performAuthenticatedRequest() -> AnyPublisher<Response, Error> {
      let url = URL(string: "https://donnys-app.com/authenticated/resource")!

      return authenticator.validToken()
        .flatMap({ token in
          // we can now use this token to authenticate the request
          session.publisher(for: url, token: token)
        })
        .tryCatch({ error -> AnyPublisher<Data, Error> in
          guard let serviceError = error as? ServiceError,
                serviceError.errors.contains(ServiceErrorMessage.invalidToken) else {
            throw error
          }

          return authenticator.validToken(forceRefresh: true)
            .flatMap({ token in
              // we can now use this new token to authenticate the second attempt at making this request
              session.publisher(for: url, token: token)
            })
            .eraseToAnyPublisher()
        })
        .decode(type: Response.self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
    }
}

enum AuthenticationError: Error {
  case loginRequired
}
class Authenticator {
  private let session: NetworkSession
  private var currentToken: CombineToken? = CombineToken(isValid: false)
  private let queue = DispatchQueue(label: "Autenticator.\(UUID().uuidString)")

  // this publisher is shared amongst all calls that request a token refresh
  private var refreshPublisher: AnyPublisher<CombineToken, Error>?

  init(session: NetworkSession = URLSession.shared) {
    self.session = session
  }

    func validToken(forceRefresh: Bool = false) -> AnyPublisher<CombineToken, Error> {
      return queue.sync { [weak self] in
        // scenario 1: we're already loading a new token
        if let publisher = self?.refreshPublisher {
          return publisher
        }

        // scenario 2: we don't have a token at all, the user should probably log in
        guard let token = self?.currentToken else {
          return Fail(error: AuthenticationError.loginRequired)
            .eraseToAnyPublisher()
        }

        // scenario 3: we already have a valid token and don't want to force a refresh
        if token.isValid, !forceRefresh {
          return Just(token)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }

        // scenario 4: we need a new token
        let endpoint = URL(string: "https://donnys-app.com/token/refresh")!
        let publisher = session.publisher(for: endpoint, token: nil)
          .share()
          .decode(type: CombineToken.self, decoder: JSONDecoder())
          .handleEvents(receiveOutput: { token in
            self?.currentToken = token
          }, receiveCompletion: { _ in
            self?.queue.sync {
              self?.refreshPublisher = nil
            }
          })
          .eraseToAnyPublisher()

        self?.refreshPublisher = publisher
        return publisher
      }
    }
}



class TestCombineNetworking {
    private var cancellable: AnyCancellable?
    private let mockNetwork = MockNetworkSession()
    func makeRequest() {
        let url = URL(string: "https://donnys-app.com/token/refresh")!
        cancellable = mockNetwork.publisher(for: url, token: nil)
            .handleEvents(receiveSubscription: { _ in
                print("Received subscription")
            }, receiveOutput: { print($0)} )
            .handleEvents(receiveCompletion: { print($0)})
            .handleEvents(receiveCancel: { print("Request cancelled")})
            .handleEvents(receiveRequest: { print($0)})
            .sink { completion in
                print(completion)
            } receiveValue: { data in
                print(String(data: data, encoding: .utf8)!)
            }
    }
}
