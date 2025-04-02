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

