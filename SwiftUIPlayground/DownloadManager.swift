//
//  DownloadManager.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 28/10/25.
//

import Foundation

enum DownloadState {
    case notStarted
    case downloading(progress: Double)
    case completed
}

protocol DownloadStateUpdateDelegate: AnyObject {
    func didUpdateDownloadState(_ downloadState: DownloadState)
}

class DownloadService: NSObject {
      var resumeData: Data?
      var downloadTask: URLSessionDownloadTask? = nil
      let session: URLSession = .shared
    
        lazy var urlSession: URLSession = {
            let configuration = URLSessionConfiguration.default
            configuration.sessionSendsLaunchEvents = true
            configuration.waitsForConnectivity = true
            let session = URLSession(configuration:configuration, delegate: self, delegateQueue: nil)
            return session
        }()
    
      func startDownload() {
          let task: URLSessionDownloadTask = session.downloadTask(with: URL(string: "https://example.com/file.zip")!)
          task.resume()
          self.downloadTask = task
      }
    
    func pauseDownload() {
        Task  {
            let data =  await  downloadTask?.cancelByProducingResumeData()
            if  data != nil  {
                resumeData = data
            }
        }
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
    }
    
    func resumeDownload() {
        if let resumeData = resumeData {
           session.downloadTask(withResumeData: resumeData)
        }
    }
}


extension DownloadService : URLSessionDownloadDelegate  {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
    }
}

// DownloadListUI - UI
// DownloadViewModel - ViewModel
// Download - Model
// DownloadService - Service
// DownloadListUI <- DownloadViewModel -> DownloadService
