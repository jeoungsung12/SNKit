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
    
    func store(_ cacheable: Cacheable) {
        memoryCache.store(cacheable)
        dispatchQueue.async { [weak self] in
            self?.diskCache.store(cacheable)
        }
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        if let image = memoryCache.retrieve(with: identifier) {
            return image
        }
        
        return dispatchQueue.sync {
            if let image = diskCache.retrieve(with: identifier) {
                if let url = URL(string: identifier) {
                    let cacheable = CacheableImage(image: image, imageURL: url, identifier: identifier)
                    DispatchQueue.main.async {
                        self.memoryCache.store(cacheable)
                    }
                }
                return image
            }
            
            return nil
        }
    }
    
    func retrieveCacheable(with identifier: String) -> Cacheable? {
        if let cacheable = memoryCache.retrieveCacheable(with: identifier) {
            return cacheable
        }
        
        return dispatchQueue.sync {
            if let cacheable = diskCache.retrieveCacheable(with: identifier) {
                DispatchQueue.main.async {
                    self.memoryCache.store(cacheable)
                }
                return cacheable
            }
            return nil
        }
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
