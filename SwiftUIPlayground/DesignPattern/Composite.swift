//
//  StorageService.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 04/02/26.
//


import UIKit

protocol StorageService {
     func upload()
}

class GoogleDriveStorageService: StorageService {
    func upload() {
        
    }
}

class DropboxStorageService: StorageService {
    func upload() {
        
    }
}

class S3StorageService: StorageService {
    func upload() {
        
    }
}

class CompositeStorageService: StorageService {
    private let services: [StorageService]
    
    init(services: [StorageService]) {
        self.services = services
    }
    
    func upload() {
        for service in services {
            service.upload()
        }
    }
}


class FileUploadViewModel {
      let storageService: StorageService
    
     init(storageService: StorageService) {
         self.storageService = storageService
         
         """
         let viewModel = FileUploadViewModel(storageService: CompositeStorageService(services: [
             GoogleDriveStorageService(),
             DropboxStorageService(),
             S3StorageService()
         ]))

         viewModel.uploadFile()
         """
    }
    
    func uploadFile() {
        storageService.upload()
    }
}

