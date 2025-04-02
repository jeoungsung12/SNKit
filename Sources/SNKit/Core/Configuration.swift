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
    public let expirationPolicy: ExpirationPolicy
    public let cacheDirectory: URL?
    public let defaultStorageOption: StorageOption
    
    public init(
        memoryCacheCapacity: Int = 50_000_000,
        diskCacheCapacity: Int = 100_000_000,
        expirationPolicy: ExpirationPolicy = ExpirationPolicy(rule: .days(7)),
        cacheDirectory: URL? = nil,
        defaultStorageOption: StorageOption = .hybrid
    ) {
        self.memoryCacheCapacity = memoryCacheCapacity
        self.diskCacheCapacity = diskCacheCapacity
        self.expirationPolicy = expirationPolicy
        self.cacheDirectory = cacheDirectory
        self.defaultStorageOption = defaultStorageOption
    }
}
