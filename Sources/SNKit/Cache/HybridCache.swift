//
//  Storage.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import Foundation

//스토리지 만료 옵션
public enum StorageExpirationOptions {
    case never
    case days(Int)
    case date(Date)
    case expired
    
    
}
