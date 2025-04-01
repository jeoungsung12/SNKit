//
//  Configuration.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import Foundation

public struct Configuration {
    public let memoryCacheCapacity: Int
    public let diskCacheCapacity: Int
    public let expirationInterval: TimeInterval
    public let cacheDirectory: URL?
    
    public init(
        memoryCacheCapacity: Int = 50_000_000,
        diskCacheCapacity: Int = 100_000_000,
        //일반적인 만료 Disk - 7일
        expirationInterval: TimeInterval = 86400 * 7,
        cacheDirectory: URL? = nil
    ) {
        self.memoryCacheCapacity = memoryCacheCapacity
        self.diskCacheCapacity = diskCacheCapacity
        self.expirationInterval = expirationInterval
        self.cacheDirectory = cacheDirectory
    }
}
