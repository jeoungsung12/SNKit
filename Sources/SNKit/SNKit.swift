// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

public final class SNKit {
    private let cacheManager: CacheManager
    private let imageProcessor: ImageProcessor
    private let session: URLSession
    private let downloader: ImageDownloader
    
    public static let shared = SNKit()
    
    public init(configuration: Configuration = Configuration()) {
        self.cacheManager = CacheManager(configuration: configuration)
        self.imageProcessor = ImageProcessor()
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: sessionConfig)
        self.downloader = ImageDownloader(session: session, cacheManager: cacheManager)
    }
    
    public func loadImage(
        from url: URL,
        cacheOption: CacheOption = .cacheFirst,
        processingOption: ImageProcessingOption = .none,
        completion: @escaping (Result<UIImage,Error>) -> Void
    ) {
        downloader.downloadImage(with: url, option: cacheOption) { [weak self] result in
            switch result {
            case .success(let image),
                    .cached(let image),
                    .validated(let image):
                //TODO: processingOption none
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
