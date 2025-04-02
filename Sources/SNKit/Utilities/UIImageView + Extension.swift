//
//  UIImageView + Extension.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

public extension UIImageView {
    
    func snSetImage(
        with url: URL,
        cacheOption: CacheOption = .cacheFirst,
        processingOption: ImageProcessingOption = .none,
        completion: ((Result<UIImage,Error>) -> Void)? = nil
    ) {
        //캐시에 이미지 존재 확인
        if let cacheImage = SNKit.shared.cachedImage(for: url),
           cacheOption == .cacheFirst {
            //TODO: 이미지 프로세서 로직 구현
            
            return
        }
        
        SNKit.shared.loadImage(
            from: url,
            cacheOption: cacheOption,
            processingOption: processingOption
        ) { [weak self] result in
            switch result {
            case .success(let image):
                self?.image = image
                completion?(.success(image))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
        
    }
    
}
