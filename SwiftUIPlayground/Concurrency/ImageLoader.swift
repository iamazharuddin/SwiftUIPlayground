//
//  ImageLoader.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 02/01/26.
//

// https://www.donnywals.com/using-swifts-async-await-to-build-an-image-loader/

import Foundation
import UIKit

actor ImageLoader {
    
let comment = """

  Fetch function - 
  1. Check if state already exist in  imageDic if yes return 
  2. Check if image is saved in filesystem if yes return 
  3. Fetch from network request, create the task and save the status in image dic 
  
"""


    
    private var images: [URLRequest: LoaderStatus] = [:]

    public func fetch(_ url: URL) async throws -> UIImage {
        let request = URLRequest(url: url)
        return try await fetch(request)
    }

    public func fetch(_ urlRequest: URLRequest) async throws -> UIImage {
        if let status = images[urlRequest] {
            switch status {
            case .inProgress(let task):
                return try await task.value
            case .fetched(let image):
                return image
            }
        }
        
        if let image = try self.imageFromFileSystem(for: urlRequest) {
            images[urlRequest] = .fetched(image)
            return image
        }
        
        let task: Task<UIImage, Error> = Task {
               let (imageData, _) = try await URLSession.shared.data(for: urlRequest)
               let image = UIImage(data: imageData)!
               try self.persistImage(image, for: urlRequest)
               return image
           }

           images[urlRequest] = .inProgress(task)

           let image = try await task.value

           images[urlRequest] = .fetched(image)
        
        return image
    }

    private enum LoaderStatus {
        case inProgress(Task<UIImage, Error>)
        case fetched(UIImage)
    }
    
    private func imageFromFileSystem(for urlRequest: URLRequest) throws -> UIImage? {
        guard let url = fileName(for: urlRequest) else {
            assertionFailure("Unable to generate a local path for \(urlRequest)")
            return nil
        }

        let data = try Data(contentsOf: url)
        return UIImage(data: data)
    }

    private func fileName(for urlRequest: URLRequest) -> URL? {
        guard let fileName = urlRequest.url?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                  return nil
              }

        return applicationSupport.appendingPathComponent(fileName)
    }
    
    private func persistImage(_ image: UIImage, for urlRequest: URLRequest) throws {
        guard let url = fileName(for: urlRequest),
              let data = image.jpegData(compressionQuality: 0.8) else {
            assertionFailure("Unable to generate a local path for \(urlRequest)")
            return
        }

        try data.write(to: url)
    }
}

import SwiftUI
struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue = ImageLoader()
}

extension EnvironmentValues {
    var imageLoader: ImageLoader {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self ] = newValue}
    }
}

struct RemoteImage: View {
    private let source: URLRequest
    @State private var image: UIImage?

    @Environment(\.imageLoader) private var imageLoader

    init(source: URL) {
        self.init(source: URLRequest(url: source))
    }

    init(source: URLRequest) {
        self.source = source
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
            } else {
                Rectangle()
                    .background(Color.red)
            }
        }
        .task {
            await loadImage(at: source)
        }
    }

    func loadImage(at source: URLRequest) async {
        do {
            image = try await imageLoader.fetch(source)
        } catch {
            print(error)
        }
    }
}
