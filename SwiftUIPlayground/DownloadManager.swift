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

class DownloadService {
      var resumeData: Data?
      var downloadTask: URLSessionDownloadTask? = nil
      let session: URLSession = .shared
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


// DownloadListUI - UI
// DownloadViewModel - ViewModel
// Download - Model
// DownloadService - Service
// DownloadListUI <- DownloadViewModel -> DownloadService
