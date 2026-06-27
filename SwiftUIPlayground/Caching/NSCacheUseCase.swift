//
//  NSCacheUseCase.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 03/03/26.
//

import Foundation
class NSCacheUseCase {
    private var cache: NSCache<NSString, NSAttributedString> = .init()
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 15 * 1024 * 1024 
    }
    
    
}
