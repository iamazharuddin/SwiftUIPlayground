//
//  Networking.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 30/01/26.
//

import Foundation
protocol MyEndpoint {
         var baseURL:String { get }
         var path: String { get }
         var method: String { get }
         var parameter:[URLQueryItem] { get }
         var headers:[String:String] { get }
}
