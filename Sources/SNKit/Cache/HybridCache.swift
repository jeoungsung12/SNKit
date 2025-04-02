//
//  Storage.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

final class HybridCache: @unchecked Sendable {
    private let memoryCache: MemoryCache
    private let diskCache: DiskCache
    private let dispatchQueue = DispatchQueue(label: "com.snkit.hybridcache", qos: .utility)
    
    init(
        memoryCache: MemoryCache,
        diskCache: DiskCache
    ) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
    }
    
    private var identifier: String = ""
    
    func store(_ cacheable: Cacheable) {
        //메모리 캐시 저장
        memoryCache.store(cacheable)
        //디스크 캐시 저장
        dispatchQueue.async { [weak self] in
            self?.diskCache.store(cacheable)
        }
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        //메모리 Hit 확인
        if let image = memoryCache.retrieve(with: identifier) {
            return image
        }
        //디스크 Hit 확인
        if let image = diskCache.retrieve(with: identifier) {
            if let url = URL(string: identifier) {
                let cacheable = CacheableImage(image: image, imageURL: url, identifier: identifier)
                memoryCache.store(cacheable)
            }
            return image
        }
        
        return nil
    }
    
    func retrieveCacheable(with identifier: String) -> Cacheable? {
        //메모리 -> 디스크 다 돌고 없으면 nil 반환 순서
        if let cacheable = memoryCache.retrieveCacheable(with: identifier) {
            return cacheable
        }
        
        if let cacheable = diskCache.retrieveCacheable(with: identifier) {
            memoryCache.store(cacheable)
            return cacheable
        }
        
        return nil
    }
    
    func remove(with identifier: String) {
        memoryCache.remove(with: identifier)
        dispatchQueue.async { [weak self] in
            self?.diskCache.remove(with: identifier)
        }
    }
    
    func removeAll() {
        memoryCache.removeAll()
        dispatchQueue.async { [weak self] in
            self?.diskCache.removeAll()
        }
    }
    
}
