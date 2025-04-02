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
        DispatchQueue.global(qos: .background).async {
            self.diskCache.store(cacheable)
        }
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        //메모리 Hit 확인
        if let image = memoryCache.retrieve(with: identifier) {
            return image
        }
        //디스크 Hit 확인
        if let image = diskCache.retrieve(with: identifier) {
            //디스크에서 찾으면 메모리에 저장을 해야하나? 하이브리드?
            return image
        }
        
        return nil
    }
    
    func remove(with identifier: String) {
        memoryCache.remove(with: identifier)
        diskCache.remove(with: identifier)
    }
    
    func removeAll() {
        memoryCache.removeAll()
        diskCache.removeAll()
    }
    
}
