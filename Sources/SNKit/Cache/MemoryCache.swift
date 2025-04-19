//
//  MemoryStorage.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

final class CacheItem: NSObject {
    let image: UIImage
    let identifier: String
    let eTag: String?
    let createdAt: Date
    var lastAccessedAt: Date
    
    init(image: UIImage, identifier: String, eTag: String? = nil, createdAt: Date = Date()) {
        self.image = image
        self.identifier = identifier
        self.eTag = eTag
        self.createdAt = createdAt
        self.lastAccessedAt = Date()
        super.init()
    }
}

final class MemoryCache {
    private let cache = NSCache<NSString, CacheItem>()
    private let logger = Logger(subsystem: "com.snkit", category: "MemoryCache")
    private let lock = NSLock()
    private var cachedItems = [String:Date]()
    
    init(capacity: Int) {
        cache.totalCostLimit = capacity
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        logger.info("메모리캐시 용량 초기화: \(capacity) bytes")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print(#function, self)
    }
    
    func store(_ cacheable: Cacheable) {
        guard let image = cacheable.image else { return }
        let key = cacheable.identifier as NSString
        
        let cacheItem = CacheItem(
            image: image,
            identifier: cacheable.identifier,
            eTag: cacheable.eTag,
            createdAt: Date()
        )
        
        let cost = calculateCost(for: image)
        
        lock.lock()
        cache.setObject(cacheItem, forKey: key, cost: cost)
        cachedItems[cacheable.identifier] = Date()
        lock.unlock()
        
        logger.debug("메모리캐시 - 저장 성공: \(cacheable.identifier), 크기: \(cost) bytes")
    }
    
    private func calculateCost(for image: UIImage) -> Int {
        let bytesPerPixel = 4
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let scale = Int(image.scale)
        
        return width * height * bytesPerPixel * scale * scale
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let cacheItem = cache.object(forKey: identifier as NSString) else {
            return nil
        }
        
        cachedItems[identifier] = Date()
        logger.debug("캐시 히트: \(identifier)")
        
        return cacheItem.image
    }
    
    func retrieveCacheable(with identifier: String) -> Cacheable? {
        guard let cacheItem = cache.object(forKey: identifier as NSString),
              let url = URL(string: identifier) else {
            return nil
        }
        
        return CacheableImage(
            image: cacheItem.image,
            imageURL: url,
            identifier: identifier,
            eTag: cacheItem.eTag
        )
    }
    
    func remove(with identifier: String) {
        cache.removeObject(forKey: identifier as NSString)
    }
    
    func removeAll() {
        cache.removeAllObjects()
    }
    
    @objc
    private func didReceiveMemoryWarning() {
        logger.warning("메모리 경고 - 메모리 최적화 필요")
        intelligentlyClearCache(percentToRemove: 0.5)
    }
    
    private func intelligentlyClearCache(percentToRemove: Double) {
        lock.lock()
        defer { lock.unlock() }
        
        let sortedItems = cachedItems.sorted { $0.value < $1.value }
        let removeCount = Int(Double(sortedItems.count) * percentToRemove)
        
        if removeCount > 0 {
            for i in 0..<removeCount {
                let item = sortedItems[i]
                cache.removeObject(forKey: item.key as NSString)
                cachedItems.removeValue(forKey: item.key)
            }
            logger.info("\(removeCount)개 - 메모리 캐시에서 삭제")
        }
    }
}


