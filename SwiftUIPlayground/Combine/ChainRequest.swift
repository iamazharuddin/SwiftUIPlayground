import Foundation
import Combine

extension URLSession {
    func publisher(for url: URL) -> AnyPublisher<Data, URLError> {
        self.dataTaskPublisher(for: url)
            .tryMap { output -> Data in
                if let http = output.response as? HTTPURLResponse,
                   !(200...299).contains(http.statusCode) {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .mapError { $0 as? URLError ?? URLError(.unknown) }
            .eraseToAnyPublisher()
    }
}

final class ApiChainRequest {
    private var cancellable: AnyCancellable?

    struct Post: Decodable { let id: Int; let title: String }
    struct Comment: Decodable { let id: Int; let name: String; let body: String }

    func fetchPostsThenComments() {
        let postsURL = URL(string: "https://jsonplaceholder.typicode.com/posts")!

        cancellable = URLSession.shared.publisher(for: postsURL)
            .timeout(.seconds(15), scheduler: DispatchQueue.main, customError: { URLError(.timedOut) })
            .retry(2)
            .handleEvents(receiveSubscription: { _ in print("📥 Fetching posts") })
            .decode(type: [Post].self, decoder: JSONDecoder())
            .tryMap { posts -> Int in
                guard let id = posts.first?.id else { throw URLError(.badServerResponse) }
                return id
            }
            .flatMap { postId -> AnyPublisher<[Comment], Error> in
                let commentsURL = URL(string: "https://jsonplaceholder.typicode.com/posts/\(postId)/comments")!
                return URLSession.shared.publisher(for: commentsURL)
                    .handleEvents(receiveSubscription: { _ in print("📥 Fetching comments for post \(postId)") })
                    .decode(type: [Comment].self, decoder: JSONDecoder())
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { print("✅ Completion:", $0) },
                receiveValue: { comments in print("💬 Comments:", comments.count) }
            )
    }
}
