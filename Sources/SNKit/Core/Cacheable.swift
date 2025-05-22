//
//  Cacheable.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

public protocol Cacheable: Sendable {
    var image: UIImage? { get set }
    var imageURL: URL { get }
    var identifier: String { get }
    var eTag: String? { get }
    var headers: RequestHeaders? { get }
}

struct CacheableImage: Cacheable {
    var image: UIImage?
    let imageURL: URL
    let identifier: String
    let eTag: String?
    var headers: RequestHeaders?
    
    public init(
        imageURL: URL,
        identifier: String? = nil,
        eTag: String? = nil,
        headers: RequestHeaders? = nil
    ) {
        self.imageURL = imageURL
        self.identifier = identifier ?? imageURL.absoluteString
        self.image = nil
        self.eTag = eTag
        self.headers = headers
    }
    
    public init(
        image: UIImage,
        imageURL: URL,
        identifier: String? = nil,
        eTag: String? = nil,
        headers: RequestHeaders? = nil
    ) {
        self.image = image
        self.imageURL = imageURL
        self.identifier = identifier ?? imageURL.absoluteString
        self.eTag = eTag
        self.headers = headers
    }
}
