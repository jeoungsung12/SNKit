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
        if let cacheImage = SNKit.shared.cachedImage(for: url),
           cacheOption == .cacheFirst {
            if processingOption != .none {
                DispatchQueue.global(qos: .userInitiated).async {
                    let imageProcessor = ImageProcessor()
                    let processedImage = imageProcessor.process(cacheImage, with: processingOption) ?? cacheImage
                    
                    DispatchQueue.main.async {
                        self.image = processedImage
                        completion?(.success(processedImage))
                    }
                }
            } else {
                self.image = cacheImage
                completion?(.success(cacheImage))
            }
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
