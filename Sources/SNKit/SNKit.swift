// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

public final class SNKit {
    private let cacheManager: CacheManager
    private let imageProcessor: ImageProcessor
    private let session: URLSession
    private let downloader: ImageDownloader
    let defaultStorageOption: StorageOption
    
    public static let shared = SNKit()
    
    public init(configuration: Configuration = Configuration()) {
        self.cacheManager = CacheManager(configuration: configuration)
        self.imageProcessor = ImageProcessor()
        self.defaultStorageOption = configuration.defaultStorageOption
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: sessionConfig)
        self.downloader = ImageDownloader(session: session, cacheManager: cacheManager)
    }
    
    public func loadImage(
        from url: URL,
        cacheOption: CacheOption = .cacheFirst,
        storageOption: StorageOption? = nil,
        processingOption: ImageProcessingOption = .none,
        completion: @escaping (Result<UIImage,Error>) -> Void
    ) {
        let storageOpt = storageOption ?? defaultStorageOption
        
        if cacheOption == .cacheFirst, let cachedImage = cacheManager.retrieveImage(with: url.absoluteString, option: storageOpt) {
            if processingOption != .none {
                if let processedImage = self.imageProcessor.process(cachedImage, with: processingOption) {
                    completion(.success(processedImage))
                } else {
                    completion(.success(cachedImage))
                }
            } else {
                completion(.success(cachedImage))
            }
            return
        }
        
        downloader.downloadImage(with: url, storageOption: storageOpt, option: cacheOption) { [weak self] result in
            switch result {
            case .success(let image),
                    .cached(let image),
                    .validated(let image):
                if processingOption != .none {
                    if let processedImage = self?.imageProcessor.process(image, with: processingOption) {
                        completion(.success(processedImage))
                    } else {
                        completion(.success(image))
                    }
                } else {
                    completion(.success(image))
                }
            case .failure(let error):
                completion(.failure(error))
            case .none:
                completion(.failure(DownloadError.invalidData))
            }
        }
    }
    
    public func cachedImage(for url: URL) -> UIImage? {
        return cacheManager.retrieveImage(with: url.absoluteString)
    }
    
    public func clearCache(option: StorageOption = .hybrid) {
        cacheManager.clearCache(option: option)
    }
    
    public func removeCache(for url: URL, option: StorageOption = .hybrid) {
        cacheManager.removeImage(with: url.absoluteString, option: option)
    }
}
