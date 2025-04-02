//
//  ETagHandler.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

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
        cachedImage: UIImage,
        cachedETag: String,
        completion: @escaping @Sendable (UIImage?) -> Void
    ) {
        var request = URLRequest(url: url)
        request.setValue(cachedETag, forHTTPHeaderField: "If-None-Match")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if httpResponse.statusCode == 304 {
                //이미지가 바뀌지 않았다면 기존의 이미지 리턴
                DispatchQueue.main.async {
                    completion(cachedImage)
                }
            } else {
                //이미지가 바뀐 경우 새로 다운로드 후 리턴
                self?.downloadAndCacheImage(with: url, completion: completion)
            }
        }
        
        task.resume()
    }
    
    private func downloadAndCacheImage(
        with url: URL,
        completion: @escaping @Sendable (UIImage?) -> Void
    ) {
        //캐시 Miss -> 데이터 통신으로 이미지 로드 후 반환
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            //TODO: ETag 추출 및 저장
            if let httpResponse = response as? HTTPURLResponse {
                let newETag: String?
                if #available(iOS 13.0, *) {
                    newETag = httpResponse.value(forHTTPHeaderField: "ETag")
                } else {
                    newETag = (httpResponse.allHeaderFields["ETag"] as? String) ??
                    (httpResponse.allHeaderFields["etag"] as? String)
                }
                if let newETag = newETag {
                    //TODO: 새로운 ETag 캐시매니저에 저장하기
                }
            }
            
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
