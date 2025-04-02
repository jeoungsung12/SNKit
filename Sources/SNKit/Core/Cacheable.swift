//
//  Cacheable.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

//TODO: 캐시 가능한 객체 프로토콜
public protocol Cacheable: Sendable {
    var image: UIImage? { get set }
    var imageURL: URL { get }
    var identifier: String { get }
    var eTag: String? { get }
}

struct CacheableImage: Cacheable {
    var image: UIImage?
    let imageURL: URL
    let identifier: String
    let eTag: String?
    
    public init(imageURL: URL, identifier: String? = nil, eTag: String? = nil) {
        self.imageURL = imageURL
        self.identifier = identifier ?? imageURL.absoluteString
        self.image = nil
        self.eTag = eTag
    }
    
    public init(image: UIImage, imageURL: URL, identifier: String? = nil, eTag: String? = nil) {
        self.image = image
        self.imageURL = imageURL
        self.identifier = identifier ?? imageURL.absoluteString
        self.eTag = eTag
    }
}
