//
//  RequestHeaders.swift
//  SNKit
//
//  Created by 정성윤 on 5/22/25.
//

import Foundation

public struct RequestHeaders {
    public let headers: [String:String]
    public init(headers: [String : String]) {
        self.headers = headers
    }
    
    public static func custom(_ headers: [String:String]) -> RequestHeaders {
        return RequestHeaders(headers: headers)
    }
}
