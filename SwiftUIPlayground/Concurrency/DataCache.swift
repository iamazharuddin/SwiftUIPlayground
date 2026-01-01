//
//  Retrancy.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 01/01/26.
//
import Foundation

class RemoteCache {
    func read(_ key: UUID, _ index:Int) async -> Data? {
        print(" network read called for \(key) - index = \(index)")
         try? await Task.sleep(nanoseconds: 1_000_000_000)
        return Data("data for \(key)".utf8)
    }
    
    func write(_ data: Data, forKey key: UUID) async throws {
        print(" network write called for \(key)")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

private actor DataCache {
  enum LoadingTask {
    case inProgress(Task<Data?, Error>)
    case loaded(Data)
  }

  private var cache: [UUID: LoadingTask] = [:]
  private let remoteCache: RemoteCache

  init(remoteCache: RemoteCache) {
    self.remoteCache = remoteCache
  }

    func read(_ key: UUID, _ index: Int) async -> Data? {
    print(" cache read called for \(key) - index = \(index)")

    // we have the data, no need to go to the network
    if case let .loaded(data) = cache[key] {
      print("cache read HIT")
      return data
    }

    // a previous call started loading the data
    if case let .inProgress(task) = cache[key] {
      print("Already in progress \(index)")
      return try? await task.value
    }

    // we don't have the data and we're not already loading it
    do {
      let task: Task<Data?, Error> = Task {
        guard let data = try await remoteCache.read(key, index) else {
          return nil
        }
        print("Return data from here \(index)")
        return data
      }

      cache[key] = .inProgress(task)
      if let data = try await task.value {
        cache[key] = .loaded(data)
        print("got the data \(index)")
        return data
      } else {
        cache[key] = nil
        return nil
      }
    } catch {
      return nil
    }
  }

  func write(_ key: UUID, data: Data) async {
    print(" cache write called for \(key)")
    defer {
      print(" cache write finished for \(key)")
    }

    do {
        try await remoteCache.write(data, forKey: key)
    } catch {
      // failed to store the data on the remote cache
    }
    cache[key] = .loaded(data)
  }
}

func performRequest() {
    let cache = DataCache(remoteCache: RemoteCache())
    let id = UUID()
    Task {
        await withTaskGroup { group in
            for i in 0..<5 {
                group.addTask {
                   await cache.read(id, i)
                }
            }
        }
    }
}
