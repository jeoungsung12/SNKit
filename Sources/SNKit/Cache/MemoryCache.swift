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
    
    init(capacity: Int) {
        cache.totalCostLimit = capacity
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
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
        
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(cacheItem, forKey: key, cost: cost)
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        return cache.object(forKey: identifier as NSString)?.image
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
        print(#function, self)
        let currentItems = getAllCachedItems()
        removeAll()
        
        let itemsToKeep = Int(Double(currentItems.count) * 0.25)
        let sortedItems = currentItems.sorted { $0.lastAccessedAt > $1.lastAccessedAt }
        
        for i in 0..<min(itemsToKeep, sortedItems.count) {
            let item = sortedItems[i]
            if let url = URL(string: item.identifier) {
                let cacheable = CacheableImage(
                    image: item.image,
                    imageURL: url,
                    identifier: item.identifier,
                    eTag: item.eTag
                )
                store(cacheable)
            }
        }
    }
    
    private func getAllCachedItems() -> [CacheItem] {
        var items = [CacheItem]()
        
        return items
    }
}


