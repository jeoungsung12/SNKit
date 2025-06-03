//
//  UIImageView + Extension.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

public extension UIImageView {
    private static var currentImageURLAssociation = ObjectAssociation<URL>()
    private static var currentTaskAssociation = ObjectAssociation<ImageLoadingTask>()

    private var snCurrentImageURL: URL? {
        get { return Self.currentImageURLAssociation[self] }
        set { Self.currentImageURLAssociation[self] = newValue }
    }

    private var snCurrentTask: ImageLoadingTask? {
        get { return Self.currentTaskAssociation[self] }
        set { Self.currentTaskAssociation[self] = newValue }
    }
    
    @discardableResult
    func snSetImage(
        with url: URL,
        headers: RequestHeaders? = nil,
        cacheOption: CacheOption = .cacheFirst,
        storageOption: StorageOption? = nil,
        processingOption: ImageProcessingOption = .none,
        completion: ((Result<UIImage,Error>) -> Void)? = nil
    ) -> ImageLoadingTask {
        snCurrentTask?.cancel()

        let newTask = ImageLoadingTask(url: url)
        snCurrentTask = newTask
        snCurrentImageURL = url
        
        let storageOpt = storageOption ?? SNKit.shared.defaultStorageOption

        if let cacheImage = SNKit.shared.cachedImage(for: url),
           cacheOption == .cacheFirst {

            if processingOption != .none {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard newTask.isValid,
                          newTask.matches(url: url),
                          self?.snCurrentTask === newTask else {
                        return
                    }
                    
                    let imageProcessor = ImageProcessor()
                    let processedImage = imageProcessor.process(cacheImage, with: processingOption) ?? cacheImage
                    
                    DispatchQueue.main.async { [weak self] in
                        guard self?.snCurrentImageURL == url,
                              self?.snCurrentTask === newTask,
                              newTask.isValid else {
                            return
                        }
                        
                        self?.image = processedImage
                        completion?(.success(processedImage))
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard self?.snCurrentImageURL == url,
                          self?.snCurrentTask === newTask,
                          newTask.isValid else {
                        return
                    }
                    
                    self?.image = cacheImage
                    completion?(.success(cacheImage))
                }
            }
            
            return newTask
        }
        
        SNKit.shared.loadImage(
            from: url,
            headers: headers,
            cacheOption: cacheOption,
            storageOption: storageOption,
            processingOption: processingOption
        ) { [weak self] result in

            guard let self = self,
                  self.snCurrentImageURL == url,
                  self.snCurrentTask === newTask,
                  newTask.isValid else {
                return
            }
            
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    guard self.snCurrentImageURL == url,
                          self.snCurrentTask === newTask,
                          newTask.isValid else {
                        return
                    }
                    
                    self.image = image
                    completion?(.success(image))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    guard self.snCurrentImageURL == url,
                          self.snCurrentTask === newTask,
                          newTask.isValid else {
                        return
                    }
                    
                    completion?(.failure(error))
                }
            }
        }
        
        return newTask
    }
    
    func snCancelImageLoading() {
        snCurrentTask?.cancel()
        snCurrentTask = nil
        snCurrentImageURL = nil
    }
    
    func snIsLoading(url: URL) -> Bool {
        guard let currentURL = snCurrentImageURL,
              let task = snCurrentTask else {
            return false
        }
        return currentURL.absoluteString == url.absoluteString && task.isValid
    }
}
