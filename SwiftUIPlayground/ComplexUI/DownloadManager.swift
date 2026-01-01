//
//  DownloadManager.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 28/10/25.
//

import Foundation
import Combine
enum DownloadState {
    case downloading(progress: Double)
    case downloaded
    case cancelled
    case failed
    case paused
    case none
}

class Download  {
    let url:URL
    var state:DownloadState = .none
    var downloadTask: URLSessionDownloadTask?
    var resumedData: Data?
    
    init(url: URL) {
        self.url = url
    }
}


struct DownloadInfo {
    let url: URL
    var downloadState: DownloadState = .none
}

protocol DownloadStateUpdateDelegate: AnyObject {
    func didUpdateDownloadState(_ downloadState: DownloadState)
}

class   DownloadService: NSObject {
    private let downloadSubject = PassthroughSubject<DownloadInfo, Never>()
    var downloadPublisher: AnyPublisher<DownloadInfo, Never> {
        downloadSubject.eraseToAnyPublisher()
    }
    static let shared  = DownloadService()
    private override init() {}
    var downloads : [URL: Download] = [:]
    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.sessionSendsLaunchEvents = true
        configuration.waitsForConnectivity = true
        configuration.isDiscretionary = true
        let session = URLSession(configuration:configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    func startDownload(  _ urlString: String) {
        //           guard let url = URL(string: urlString) else { return }
        //           let download = Download(url: url)
        //           let task: URLSessionDownloadTask = session.downloadTask(with: download.url)
        //           download.downloadTask = task
        //           download.downloadTask?.resume()
        //           downloads[url] = download
        
        
        
        
        Task {
            do {
                let url =  URL(string: urlString)!
                let (asyncBytes, urlResponse) = try await session.bytes(from: url)
                let length = (urlResponse.expectedContentLength)
                let gb_total = Double(length) / 1024 / 1024 / 1024
                
                var data = Data()
                data.reserveCapacity(Int(length))
                
                var downloaded:Int64 = 0
                for  try await byte in asyncBytes {
                    data.append(byte)
                    let progress = Double(data.count) / Double(length)
                    let gb = Double(data.count) / 1024 / 1024 / 1024
                    let formatted_gb_total = String(format: "%.3f", gb_total)
                    let formatted_gg_loaded = String(format: "%.3f", gb)
                    
                    try await Task.sleep(for: .seconds(0.000005))
                    downloadSubject.send(DownloadInfo(url: url, downloadState:.downloading(progress: progress)))
                }

                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
               
                let fileURL  = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                
                try? data.write(to: fileURL)
                try? FileManager.default.moveItem(at: url, to: fileURL)
                downloadSubject.send(DownloadInfo(url: url, downloadState: .downloaded))
            } catch {
                
            }
        }
    }
    
    func pauseDownload(  _ urlString: String) {
        Task {
            guard let url = URL(string: urlString), var download = downloads[url] else { return }
            let data =  await download.downloadTask?.cancelByProducingResumeData()
            download.resumedData = data
            download.state = .paused
            downloads[url] = download
        }
    }
    
    func cancelDownload( _ urlString: String) {
        guard let url = URL(string: urlString), var download = downloads[url] else { return }
        download.downloadTask?.cancel()
        download.state = .cancelled
        downloads[url] = download
    }
    
    func resumeDownload( _ urlString:String) {
        guard let url = URL(string: urlString), var download = downloads[url] else { return }
        if let data = download.resumedData {
            download.downloadTask =    session.downloadTask(withResumeData: data)
        } else {
            download.downloadTask =   session.downloadTask(with: url)
        }
        downloads[url] = download
    }
}


extension DownloadService : URLSessionDownloadDelegate  {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,  didFinishDownloadingTo location: URL) {
        if let url = downloadTask.originalRequest?.url {
            let urlString = downloadTask.originalRequest?.url?.absoluteString
            debugPrint("DEBUG: \(urlString)")
            downloadSubject.send(DownloadInfo(url: url, downloadState: .downloaded))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let url = downloadTask.originalRequest?.url {
            let progress  = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            debugPrint("DEBUG: \(progress)")
            downloadSubject.send(DownloadInfo(url: url, downloadState:.downloading(progress: progress)))
        }
    }
}

// DownloadListUI - UI
// DownloadViewModel - ViewModel
// Download - Model
// DownloadService - Service
// DownloadListUI <- DownloadViewModel -> DownloadService



