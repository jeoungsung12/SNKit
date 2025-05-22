//
//  ETagHandler.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

enum ETagValidationResult {
    case reused(UIImage) //이미지 변경 X 304
    case fresh(UIImage) //이미지 변경
    case error(Error)
}

final class ETagHandler: @unchecked Sendable {
    private let session: URLSession
    private let cacheManager: CacheManager
    
    init(
        session: URLSession,
        cacheManager: CacheManager
    ) {
        self.session = session
        self.cacheManager = cacheManager
    }
    
    func validateFetchImage(
        with url: URL,
        headers: RequestHeaders? = nil,
        cachedImage: UIImage,
        cachedETag: String,
        completion: @escaping @Sendable (ETagValidationResult) -> Void
    ) {
        var request = URLRequest(url: url)
        request.setValue(cachedETag, forHTTPHeaderField: "If-None-Match")
        if let requestHeaders = headers {
            for (key, value) in requestHeaders.headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        let task = session.dataTask(with: request) {
            [weak self] data,
            response,
            error in
            
            if let error = error {
                completion(.error(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.error(DownloadError.invalidResponse))
                }
                return
            }
            
            if httpResponse.statusCode == 304 {
                //이미지가 바뀌지 않았다면 기존의 이미지 리턴
                DispatchQueue.main.async {
                    completion(.reused(cachedImage))
                }
            } else if httpResponse.statusCode == 200 {
                //이미지가 바뀐 경우 새로 다운로드 후 리턴
                guard let data = data,
                      let image = UIImage(data: data) else {
                    completion(.error(DownloadError.invalidData))
                    return
                }
                
                let newETag: String?
                if #available(iOS 13.0, *) {
                    newETag = httpResponse.value(forHTTPHeaderField: "ETag")
                } else {
                    newETag = (httpResponse.allHeaderFields["ETag"] as? String) ??
                    (httpResponse.allHeaderFields["etag"] as? String)
                }
                
                let identifier = url.absoluteString
                if let newETag = newETag,
                   let imageURL = URL(string: identifier) {
                    let cacheable = CacheableImage(
                        image: image,
                        imageURL: imageURL,
                        identifier: identifier,
                        eTag: newETag
                    )
                    self?.cacheManager.storeImage(with: cacheable)
                }
                
                completion(.fresh(image))
            } else {
                completion(.error(DownloadError.invalidResponse))
            }
        }
        task.resume()
    }
}
