//
//  ImageDownloader.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

public enum CacheOption {
    case cacheFirst
    case eTagValidation
    case forceDownload
}

final class ImageDownloader: @unchecked Sendable {
    private let session: URLSession
    private let cacheManager: CacheManager
    
    init(
        session: URLSession,
        cacheManager: CacheManager
    ) {
        self.session = session
        self.cacheManager = cacheManager
    }
    
    func downloadImage(with url: URL, option: CacheOption = .cacheFirst , completion: @escaping (UIImage?) -> Void) {
        //캐시 확인
        let identifier = url.absoluteString
        switch option {
        case .cacheFirst:
            //캐시 Hit -> 캐시에 저장된 이미지 반환
            if let cachedImage = cacheManager.retrieveImage(with: identifier) {
                completion(cachedImage)
                return
            }
            downloadAndCacheImage(with: url, identifier: identifier, completion: completion)
        case .eTagValidation:
            //TODO: Etag 검증, 캐시 Hit -> Etag 확인, 없으면 그냥 다운
            if let cacheImage = cacheManager.retrieveImage(with: identifier) {
                
            }
               
        case .forceDownload:
            downloadAndCacheImage(with: url, identifier: identifier, completion: completion)
        }
        
        
    }
    
    private func validateETag(with url: URL, cachedETag: String, completion: @escaping (Bool) -> Void) {
        
    }
    
    private func downloadAndCacheImage(with url: URL, identifier: String, completion: @escaping (UIImage?) -> Void) {
        //캐시 Miss -> 데이터 통신으로 이미지 로드 후 반환
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    //TODO: Sendable?
                    completion(nil)
                }
                return
            }
            
            //TODO: ETag 추출 및 저장
            
            
            //가져온 이미지를 캐시에 저장
            let cacheable = CacheableImage(image: image, imageURL: url)
            self?.cacheManager.storeImage(with: cacheable)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        task.resume()
    }
}

