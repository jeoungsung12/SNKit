//
//  ImageDownloader.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

final class ImageDownloader {
    private let session: URLSession
    private let cacheManager: CacheManager
    
    init(
        session: URLSession,
        cacheManager: CacheManager
    ) {
        self.session = session
        self.cacheManager = cacheManager
    }
    
    func downloadImage(with url: URL, completion: @escaping (UIImage?) -> Void) {
        //캐시 확인
        let identifier = url.absoluteString
        //캐시 Hit -> 캐시에 저장된 이미지 반환
        if let cachedImage = cacheManager.retrieveImage(with: identifier) {
            completion(cachedImage)
            return
        }
        
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

