//
//  BGDownload.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 17/01/26.
//

// https://developer.apple.com/documentation/Foundation/downloading-files-in-the-background
import Foundation
class BGDownload: NSObject {
    private var downloadTask: URLSessionDownloadTask!
    private var resumeData:Data?
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "MySession")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    func startDownload() {
        let urlString = "https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf"
        let url = URL(string: urlString)!
        let backgroundTask = urlSession.downloadTask(with: url)
        backgroundTask.earliestBeginDate = Date().addingTimeInterval(60 * 60)
        backgroundTask.countOfBytesClientExpectsToSend = 200
        backgroundTask.countOfBytesClientExpectsToReceive = 500 * 1024
        backgroundTask.resume()
    }
    
    func pauseDownload() {
         downloadTask.cancel { resumeDataOrNil in
            guard let resumeData = resumeDataOrNil else {
              // download can't be resumed; remove from UI if necessary
              return
            }
            self.resumeData = resumeData
        }
    }
    
    func resumeDownloa() {
         guard let resumeData = resumeData else {
            return
        }
        downloadTask = urlSession.downloadTask(withResumeData: resumeData)
        downloadTask.resume()
    }
}

extension BGDownload: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print(location)
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
         DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let backgroundCompletionHandler =
                appDelegate.backgroundCompletionHandler else {
                    return
            }
            backgroundCompletionHandler()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            // Handle success case.
            return
        }
        let userInfo = (error as NSError).userInfo
        if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            self.resumeData = resumeData
        }
        // Perform any other error handling.
    }
}


import UIKit
extension AppDelegate {
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
            backgroundCompletionHandler = completionHandler
    }
}
