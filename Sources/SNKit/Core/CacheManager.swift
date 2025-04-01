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

public final class CacheManager {
    
    func store(with cachable: Cacheable) {
        
    }
    
    func retrieveImage(with identifier: String) -> UIImage? {
        
    }
}

//public protocol CacheManagerType {
//    func load(url: NSURL, item: Cacheable, completion: @escaping (Cacheable,UIImage?) -> Void)
//}
//
//public final class CacheManager: CacheManagerType {
//    
//    //캐시 옵션(메모리, 디스크, 하이브리드)
//    @frozen
//    public enum ImageCacheOption {
//        case memory
//        case disk
//        case hybrid //memory + disk
//    }
//    
//    @MainActor
//    static let shared = CacheManager()
//    private init() { }
//    
//    private let memoryCache = NSCache<NSURL, UIImage>()
//    //    private let diskCache =
//    
//    private final func image(url: NSURL) -> UIImage? {
//        //메모리 캐시에 존재하면(key=NSURL) -> Image 반환
//        return memoryCache.object(forKey: url)
//    }
//    
//    //캐시에서 이미지 Hit를 확인해 -> 반환(없을 경우 통신으로 로드)
//    //메모리 캐시 확인 -> 디스크 캐시 확인 -> 없을 경우 데이터 통신
//    public final func load(url: NSURL, item: Cacheable, completion: @escaping (Cacheable,UIImage?) -> Void) {
//        //1. 메모리 캐시 Hit -> 캐시에 저장된 이미지 반환
//        if let memoryCachedImage = self.image(url: url) {
//            completion(item, memoryCachedImage)
//            return
//        }
//        
//        //2. 디스크 캐시 Hit
//        
//        //3. 데이터 통신으로 이미지 로드 후 반환
//        
//        
//    }
//    
//}
