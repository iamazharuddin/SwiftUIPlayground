import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
import Foundation
import Combine

class NetworkService {
    var cancellables: Set<AnyCancellable> = []
    func apiCall() {
        URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.google.com")!)
            .map { $0.data }
            .sink { completion in
                print(completion)
            } receiveValue: { data in
                print(data.count)
            }
            .store(in: &cancellables)
        
    }
    
    func apiCall2() {
        let url1 = URL(string: "https://www.google.com")!
        let url2 = URL(string: "https://jsonplaceholder.typicode.com/users")!
        
        URLSession.shared.dataTaskPublisher(for: url1)
            .flatMap { _ in
                // second API call starts after first finishes
                URLSession.shared.dataTaskPublisher(for: url2)
            }
            .sink(
                receiveCompletion: { completion in
                    print("Completion:", completion)
                },
                receiveValue: { _, response in
                    print("Second API response received:",
                          (response as? HTTPURLResponse)?.statusCode ?? -1)
                }
            )
            .store(in: &cancellables)
    }
}


class ViewModel {
      func apiCall() {
         NetworkService().apiCall2()
    }
}

let vm = ViewModel()
vm.apiCall()
