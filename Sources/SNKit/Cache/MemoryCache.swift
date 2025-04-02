//
//  MemoryStorage.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

//NSCache 스레드 세이프. read-only 작업만 할 시에는 -> NSLock이 필요한가?(etc. Actor)
//저장이나 삭제할 시에는? NSLock이 필요한가?
final class MemoryCache {
    private let cache = NSCache<NSString, UIImage>()
    
    init(capacity: Int) {
        //메모리 최대 용량 설정
        cache.totalCostLimit = capacity
        
        //TODO: 메모리 최대 용량을 넘어설때 알림
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
        
        
        
        
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key, cost: cost)
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        return cache.object(forKey: identifier as NSString)
    }
    
    func retrieveCacheable(with identifier: String) -> Cacheable? {
        guard let cachedObject = cache.object(forKey: identifier as NSString),
              let url = URL(string: identifier) else {
            return nil
        }
        
        return CacheableImage(
            image: cachedObject,
            imageURL: url,
            identifier: identifier
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
        removeAll()
    }
}


