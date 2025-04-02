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
    private let eTagHandler: ETagHandler
    
    init(
        session: URLSession,
        cacheManager: CacheManager
    ) {
        self.session = session
        self.cacheManager = cacheManager
        self.eTagHandler = ETagHandler(session: session, cacheManager: cacheManager)
    }
    
    func downloadImage(
        with url: URL,
        option: CacheOption = .cacheFirst ,
        completion: @escaping @Sendable (UIImage?) -> Void
    ) {
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
            if let cachedImage = cacheManager.retrieveImage(with: identifier),
               let cachedETag = cacheManager.retrieveETag(with: identifier) {
                eTagHandler.validateFetchImage(
                    with: url,
                    cachedImage: cachedImage,
                    cachedETag: cachedETag,
                    completion: completion
                )
            } else {
                downloadAndCacheImage(with: url, identifier: identifier, completion: completion)
            }
            
        case .forceDownload:
            downloadAndCacheImage(with: url, identifier: identifier, completion: completion)
        }
    }
    
    private func downloadAndCacheImage(
        with url: URL,
        identifier: String,
        completion: @escaping @Sendable (UIImage?) -> Void
    ) {
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let newETag: String?
                if #available(iOS 13.0, *) {
                    newETag = httpResponse.value(forHTTPHeaderField: "ETag")
                } else {
                    newETag = (httpResponse.allHeaderFields["ETag"] as? String) ??
                    (httpResponse.allHeaderFields["etag"] as? String)
                }
                if let newETag = newETag {
                    let cacheable = CacheableImage(image: image, imageURL: url, identifier: identifier, eTag: newETag)
                    self?.cacheManager.storeImage(with: cacheable)
                } else {
                    let cacheable = CacheableImage(image: image, imageURL: url, identifier: identifier)
                    self?.cacheManager.storeImage(with: cacheable)
                }
            }
            
            let cacheable = CacheableImage(image: image, imageURL: url)
            self?.cacheManager.storeImage(with: cacheable)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
        task.resume()
    }
    
}

