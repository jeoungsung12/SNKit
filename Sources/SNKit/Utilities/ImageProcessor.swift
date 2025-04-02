//
//  ImageProcessor.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

// 이미지 처리 옵션
public enum ImageProcessingOption {
    case resize(CGSize)
    case downsample(CGSize)
    case none
}

final class ImageProcessor {
    
    func process(_ image: UIImage, with option: ImageProcessingOption) -> UIImage? {
        switch option {
        case .resize(let size):
            return resizeImage(image, to: size)
        case .downsample(let size):
            return downsampleImage(image, to: size)
        case .none:
            return image
        }
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func downsampleImage(_ image: UIImage,to size: CGSize) -> UIImage? {
        guard let data = image.jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
}
