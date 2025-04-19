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
    private let logger = Logger(subsystem: "com.snkit", category: "HybridCache")
    private let operationQueue: OperationQueue
    
    init(
        memoryCache: MemoryCache,
        diskCache: DiskCache
    ) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
        
        operationQueue = OperationQueue()
        operationQueue.name = "com.snkit.hybridcache.operations"
        operationQueue.maxConcurrentOperationCount = 4
        
        logger.info("하이브리드 캐시 초기화")
    }
    
    func store(_ cacheable: Cacheable) {
        memoryCache.store(cacheable)
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }
            do {
                try self.diskCache.store(cacheable)
            } catch {
                self.logger.error("디스크 캐시 저장 실패: \(error.localizedDescription)")
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        if let image = memoryCache.retrieve(with: identifier) {
            logger.debug("메모리 캐시 히트: \(identifier)")
            return image
        }
        
        logger.debug("메모리 캐시 미스, 디스크 캐시 확인: \(identifier)")
        
        return dispatchQueue.sync {
            if let image = diskCache.retrieve(with: identifier) {
                logger.debug("디스크 캐시 히트: \(identifier)")
                
                if let url = URL(string: identifier) {
                    let cacheable = CacheableImage(image: image, imageURL: url, identifier: identifier)
                    DispatchQueue.main.async {
                        self.memoryCache.store(cacheable)
                    }
                }
                return image
            }
            
            logger.debug("디스크 캐시 미스: \(identifier)")
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
