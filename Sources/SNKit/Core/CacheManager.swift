//
//  CacheManager.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit
//TODO: 캐시 메인 로직(메모리/디스크/하이브리드 조율)
//TODO: 캐시 정책은? 알고리즘? ETag? Memory? Disk? Prefetch? Realm? 동시성?

struct CacheableImage: Cacheable {
    var image: UIImage?
    let imageURL: URL
    let identifier: String
    
    public init(imageURL: URL, identifier: String? = nil) {
        self.imageURL = imageURL
        self.identifier = identifier ?? imageURL.absoluteString
        self.image = nil
    }
    
    public init(image: UIImage, imageURL: URL, identifier: String? = nil) {
        self.image = image
        self.imageURL = imageURL
        self.identifier = identifier ?? imageURL.absoluteString
    }
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
    
    func storeImage(with cachable: Cacheable) {
        //TODO: 옵션에 따라 처리
        memoryCache.store(cachable)
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            //TODO: Sendable?
            self?.diskCache.store(cachable)
        }
        
        //하이브리드 캐시일때?
    }
    
    func retrieveImage(with identifier: String) -> UIImage? {
        //TODO: 옵션에 따라 처리
        
        //1. 메모리 캐시 Hit
        if let image = memoryCache.retrieve(with: identifier) {
            return image
        }
        
        //2. 디스크 캐시 Hit
        if let image = diskCache.retrieve(with: identifier) {
            //메모리 캐시에도 저장해야하는가? or 바로 반환
            return image
        }
        
        //하이브리드일때!
        
        return nil
    }
    
    func removeImage(with identifier: String) {
        //1. 메모리 캐시 삭제
        memoryCache.remove(with: identifier)
        
        //2. 디스크 캐시 삭제
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.diskCache.remove(with: identifier)
        }
        
        //하이브리드일때
    }
    
    func clearCache() {
        //메모리, 디스크 모두 삭제
        memoryCache.removeAll()
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.diskCache.removeAll()
        }
    }
}
