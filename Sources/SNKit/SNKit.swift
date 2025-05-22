// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

public final class SNKit {
    let cacheManager: CacheManager
    let imageProcessor: ImageProcessor
    let session: URLSession
    let downloader: ImageDownloader
    public let defaultStorageOption: StorageOption
    
    private let logger = Logger(subsystem: "com.snkit", category: "SNKit")
    public static let shared = SNKit()
    
    init(
        configuration: Configuration = Configuration(),
        session: URLSession? = nil,
        cacheManager: CacheManager? = nil,
        imageProcessor: ImageProcessor? = nil
    ) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        let finalSession = session ?? URLSession(configuration: sessionConfig)
        
        let finalCacheManager = cacheManager ?? CacheManager(configuration: configuration)
        let finalImageProcessor = imageProcessor ?? ImageProcessor()
        
        self.cacheManager = finalCacheManager
        self.imageProcessor = finalImageProcessor
        self.defaultStorageOption = configuration.defaultStorageOption
        self.session = finalSession
        
        self.downloader = ImageDownloader(
            session: finalSession,
            cacheManager: finalCacheManager
        )
        
        logger.info("SNKit 초기화 - 속성: \(configuration)")
    }
    
    public func loadImage(
        from url: URL,
        headers: RequestHeaders? = nil,
        cacheOption: CacheOption = .cacheFirst,
        storageOption: StorageOption? = nil,
        processingOption: ImageProcessingOption = .none,
        completion: @escaping (Result<UIImage,Error>) -> Void
    ) {
        let storageOpt = storageOption ?? defaultStorageOption
        
        if cacheOption == .cacheFirst, let cachedImage = cacheManager.retrieveImage(with: url.absoluteString, option: storageOpt) {
            logger.debug("캐시 히트 - URL: \(url.absoluteString)")
            processAndDeliver(image: cachedImage, with: processingOption, completion: completion)
            return
        }
        
        logger.debug("캐시 미스/캐시옵션 지정 X - URL: \(url.absoluteString)")
        downloader.downloadImage(
            with: url,
            headers: headers,
            storageOption: storageOpt,
            option: cacheOption
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let image), .cached(let image), .validated(let image):
                self.logger.info("이미지 로드 성공: \(url.absoluteString)")
                self.processAndDeliver(image: image, with: processingOption, completion: completion)
            case .failure(let error):
                self.logger.error("이미지 로드 실패: \(error.localizedDescription)")
                completion(.failure(error))
            case .none:
                let error = DownloadError.invalidData
                self.logger.error("유효하지 않은 이미지: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    private func processAndDeliver(image: UIImage, with option: ImageProcessingOption, completion: @escaping (Result<UIImage,Error>) -> Void) {
        if option != .none {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                if let processedImage = self.imageProcessor.process(image, with: option) {
                    DispatchQueue.main.async {
                        completion(.success(processedImage))
                    }
                } else {
                    self.logger.warning("이미지 Processor 작업 실패, 원본 이미지 반환")
                    DispatchQueue.main.async {
                        completion(.success(image))
                    }
                }
            }
        } else {
            completion(.success(image))
        }
    }
    
    public func cachedImage(for url: URL) -> UIImage? {
        return cacheManager.retrieveImage(with: url.absoluteString)
    }
    
    public func clearCache(option: StorageOption = .hybrid) {
        logger.info("캐시 모두 지우기: \(option)")
        cacheManager.clearCache(option: option)
    }
    
    public func removeCache(for url: URL, option: StorageOption = .hybrid) {
        logger.debug("캐시에서 이미지 지우기: \(url.absoluteString)")
        cacheManager.removeImage(with: url.absoluteString, option: option)
    }
}

public extension SNKit {
    static func clearCache(for url: URL? = nil, option: StorageOption = .hybrid) {
        if let specificURL = url {
            SNKit.shared.removeCache(for: specificURL, option: option)
        } else {
            SNKit.shared.clearCache(option: option)
        }
    }
}
