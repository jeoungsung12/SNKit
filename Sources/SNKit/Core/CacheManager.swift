//
//  CacheManager.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

public enum StorageOption {
    case memory
    case disk
    case hybrid
}

public final class CacheManager: @unchecked Sendable {
    private let memoryCache: MemoryCache
    private let diskCache: DiskCache
    private let hybridCache: HybridCache
    
    init(configuration: Configuration) {
        self.memoryCache = MemoryCache(capacity: configuration.memoryCacheCapacity)
        self.diskCache = DiskCache(
            directory: configuration.cacheDirectory,
            capacity: configuration.diskCacheCapacity,
            expirationInterval: configuration.expirationInterval
        )
        self.hybridCache = HybridCache(
            memoryCache: self.memoryCache,
            diskCache: self.diskCache
        )
    }
    
    func storeImage(with cachable: Cacheable, option: StorageOption = .hybrid) {
        switch option {
        case .memory:
            memoryCache.store(cachable)
        case .disk:
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.diskCache.store(cachable)
            }
        case .hybrid:
            hybridCache.store(cachable)
        }
    }
    
    func retrieveImage(with identifier: String, option: StorageOption = .hybrid) -> UIImage? {
        switch option {
        case .memory:
            //1. 메모리 캐시 Hit
            return memoryCache.retrieve(with: identifier)
        case .disk:
            //2. 디스크 캐시 Hit
            return diskCache.retrieve(with: identifier)
        case .hybrid:
            //3. 하이브리드 캐시 Hit
            return hybridCache.retrieve(with: identifier)
        }
    }
    
    func removeImage(with identifier: String, option: StorageOption = .hybrid) {
        switch option {
        case .memory:
            //1. 메모리 캐시 삭제
            memoryCache.remove(with: identifier)
        case .disk:
            //2. 디스크 캐시 삭제
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.diskCache.remove(with: identifier)
            }
        case .hybrid:
            hybridCache.remove(with: identifier)
        }
    }
    
    func clearCache(option: StorageOption = .hybrid) {
        switch option {
        case .memory:
            memoryCache.removeAll()
        case .disk:
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.diskCache.removeAll()
            }
        case .hybrid:
            hybridCache.removeAll()
        }
    }
}

//MARK: ETag
extension CacheManager {
    
    func storeETag(_ eTag: String, with identifier: String, option: StorageOption = .hybrid) {
        switch option {
        case .memory:
            if let cachedImage = memoryCache.retrieve(with: identifier),
               let url = URL(string: identifier) {
                let updated = CacheableImage(image: cachedImage, imageURL: url, identifier: identifier, eTag: eTag)
                memoryCache.store(updated)
            }
        case .disk:
            if let cachedImage = diskCache.retrieve(with: identifier),
               let url = URL(string: identifier) {
                let updated = CacheableImage(image: cachedImage, imageURL: url, identifier: identifier, eTag: eTag)
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    self?.diskCache.store(updated)
                }
            }
        case .hybrid:
            if let cachedImage = hybridCache.retrieve(with: identifier),
               let url = URL(string: identifier) {
                let updated = CacheableImage(image: cachedImage, imageURL: url, identifier: identifier, eTag: eTag)
                hybridCache.store(updated)
            }
        }
    }
    
    func retrieveETag(with identifier: String, option: StorageOption = .hybrid) -> String? {
        switch option {
        case .memory:
            return memoryCache.retrieveCacheable(with: identifier)?.eTag
        case .disk:
            return diskCache.retrieveCacheable(with: identifier)?.eTag
        case .hybrid:
            return hybridCache.retrieveCacheable(with: identifier)?.eTag
        }
    }
    
}
