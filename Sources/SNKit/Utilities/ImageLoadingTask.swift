//
//  ImageLoadingTask.swift
//  SNKit
//
//  Created by 정성윤 on 6/4/25.
//

import Foundation

public final class ImageLoadingTask {
    private let url: URL
    private var isCancelled = false
    private let logger = Logger(subsystem: "com.snkit", category: "ImageLoadingTask")
    
    init(url: URL) {
        self.url = url
    }
    
    public func cancel() {
        isCancelled = true
        logger.debug("이미지 로딩 작업 취소: \(url.absoluteString)")
    }
    
    var isValid: Bool {
        return !isCancelled
    }
    
    func matches(url: URL) -> Bool {
        return self.url.absoluteString == url.absoluteString
    }
}
