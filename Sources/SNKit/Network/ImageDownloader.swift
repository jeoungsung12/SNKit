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

public enum DownloadResult {
    case success(UIImage)
    case cached(UIImage)
    case validated(UIImage)
    case failure(Error)
}

public enum DownloadError: Error {
    case invalidData
    case networkError(Error)
    case invalidResponse
    case imageProcessingFailed
}

final class ImageDownloader: @unchecked Sendable {
    private let session: URLSession
    private let cacheManager: CacheManager
    private let eTagHandler: ETagHandler
    private let dispatchQueue = DispatchQueue(label: "com.snkit.imagedownloader", qos: .utility, attributes: .concurrent)
    
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
        completion: @escaping @Sendable (DownloadResult?) -> Void
    ) {
        //캐시 확인
        let identifier = url.absoluteString
        
        switch option {
        case .cacheFirst:
            //캐시 Hit -> 캐시에 저장된 이미지 반환
            if let cachedImage = cacheManager.retrieveImage(with: identifier) {
                DispatchQueue.main.async {
                    completion(.cached(cachedImage))
                }
                return
            }
            downloadAndCacheImage(with: url, identifier: identifier, completion: completion)
            
        case .eTagValidation:
            //TODO: Etag 검증, 캐시 Hit -> Etag 확인, 없으면 그냥 다운
            if let cachedImage = cacheManager.retrieveImage(with: identifier),
               let cachedETag = cacheManager.retrieveETag(with: identifier) {
                validateWithETag(
                    url: url,
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
    
}


extension ImageDownloader {
    
    private func validateWithETag(
        url: URL,
        cachedImage: UIImage,
        cachedETag: String,
        completion: @escaping @Sendable (DownloadResult) -> Void
    ) {
        dispatchQueue.async { [weak self] in
            self?.eTagHandler.validateFetchImage(
                with: url,
                cachedImage: cachedImage,
                cachedETag: cachedETag
            ) { result in
                switch result {
                case .reused(let image):
                    DispatchQueue.main.async {
                        completion(.validated(image))
                    }
                case .fresh(let image):
                    DispatchQueue.main.async {
                        completion(.success(image))
                    }
                case .error(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    private func downloadAndCacheImage(
        with url: URL,
        identifier: String,
        completion: @escaping @Sendable (DownloadResult) -> Void
    ) {
        dispatchQueue.async { [weak self] in
            let task = self?.session.dataTask(with: url) {
                [weak self] data,
                response,
                error in
                
                //에러처리
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(DownloadError.networkError(error)))
                    }
                    return
                }
                
                //데이터 유효한지?
                guard let data = data,
                      !data.isEmpty else {
                    DispatchQueue.main.async {
                        completion(.failure(DownloadError.invalidData))
                    }
                    return
                }
                
                //이미지 유효?
                guard let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        completion(.failure(DownloadError.invalidData))
                    }
                    return
                }
                
                var eTag: String? = nil
                if let httpResponse = response as? HTTPURLResponse {
                    if #available(iOS 13.0, *) {
                        eTag = httpResponse.value(forHTTPHeaderField: "ETag")
                    } else {
                        eTag = (httpResponse.allHeaderFields["ETag"] as? String) ??
                        (httpResponse.allHeaderFields["etag"] as? String)
                    }
                }
                
                guard let url = URL(string: identifier) else {
                    DispatchQueue.main.async {
                        completion(.success(image))
                    }
                    return
                }
                
                let cacheable = CacheableImage(
                    image: image,
                    imageURL: url,
                    identifier: identifier,
                    eTag: eTag
                )
                
                self?.cacheManager.storeImage(with: cacheable)
                
                DispatchQueue.main.async {
                    completion(.success(image))
                }
            }
            task?.resume()
        }
    }
}
