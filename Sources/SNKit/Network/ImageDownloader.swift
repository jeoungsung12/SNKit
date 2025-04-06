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
    case invalidURL
}

final class ImageDownloader: @unchecked Sendable {
    private let session: URLSession
    private let cacheManager: CacheManager
    private let eTagHandler: ETagHandler
    private let dispatchQueue = DispatchQueue(label: "com.snkit.imagedownloader", qos: .utility, attributes: .concurrent)
    
    private var activeTasks: [String: URLSessionDataTask] = [:]
    private let taskLock = NSLock()
    
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
        storageOption: StorageOption = .hybrid,
        option: CacheOption = .cacheFirst ,
        completion: @escaping @Sendable (DownloadResult?) -> Void
    ) {
        let identifier = url.absoluteString
        
        taskLock.lock()
        if let existingTask = activeTasks[identifier], existingTask.state == .running {
            taskLock.unlock()
            return
        }
        taskLock.unlock()
        
        switch option {
        case .cacheFirst:
            if let cachedImage = cacheManager.retrieveImage(with: identifier) {
                DispatchQueue.main.async {
                    completion(.cached(cachedImage))
                }
                return
            }
            downloadAndCacheImage(with: url, identifier: identifier, storageOption: storageOption, completion: completion)
            
        case .eTagValidation:
            if let cachedImage = cacheManager.retrieveImage(with: identifier),
               let cachedETag = cacheManager.retrieveETag(with: identifier) {
                validateWithETag(
                    url: url,
                    cachedImage: cachedImage,
                    cachedETag: cachedETag,
                    completion: completion
                )
            } else {
                downloadAndCacheImage(with: url, identifier: identifier, storageOption: storageOption, completion: completion)
            }
            
        case .forceDownload:
            downloadAndCacheImage(with: url, identifier: identifier, storageOption: storageOption, completion: completion)
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
        storageOption: StorageOption = .hybrid,
        completion: @escaping @Sendable (DownloadResult) -> Void
    ) {
        dispatchQueue.async { [weak self] in
            let task = self?.session.dataTask(with: url) {
                [weak self] data,
                response,
                error in
                
                self?.taskLock.lock()
                self?.activeTasks.removeValue(forKey: identifier)
                self?.taskLock.unlock()
                
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(DownloadError.networkError(error)))
                    }
                    return
                }
                
                guard let data = data,
                      !data.isEmpty else {
                    DispatchQueue.main.async {
                        completion(.failure(DownloadError.invalidData))
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(DownloadError.invalidResponse))
                    }
                    return
                }
                
                guard let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        completion(.failure(DownloadError.invalidData))
                    }
                    return
                }
                
                var eTag: String? = nil
                if #available(iOS 13.0, *) {
                    eTag = httpResponse.value(forHTTPHeaderField: "ETag")
                } else {
                    eTag = (httpResponse.allHeaderFields["ETag"] as? String) ??
                    (httpResponse.allHeaderFields["etag"] as? String)
                }
                
                guard let url = URL(string: identifier) else {
                    DispatchQueue.main.async {
                        completion(.failure(DownloadError.invalidURL))
                    }
                    return
                }
                
                let cacheable = CacheableImage(
                    image: image,
                    imageURL: url,
                    identifier: identifier,
                    eTag: eTag
                )
                
                self?.cacheManager.storeImage(with: cacheable, option: storageOption)
                
                DispatchQueue.main.async {
                    completion(.success(image))
                }
            }
            
            self?.taskLock.lock()
            self?.activeTasks[identifier] = task
            self?.taskLock.unlock()
            
            task?.resume()
        }
    }
}
