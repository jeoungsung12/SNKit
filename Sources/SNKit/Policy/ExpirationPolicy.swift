//
//  ExpirationPolicy.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import Foundation

struct TimeConstants {
    static let secondsInOneDay = 86_400
}

//캐시 정책
public struct ExpirationPolicy: Sendable {
    public enum Rule: Sendable {
        case never
        case days(Int)
        case date(Date)
        case expired
    }
    
    private let rule: Rule
    
    public init(rule: Rule) {
        self.rule = rule
    }
    
    public func isExpired(
        createdAt: Date,
        currentDate: Date = Date()
    ) -> Bool {
        switch rule {
        case .never:
            return false
        case .days(let days):
            let interval = TimeInterval(days * TimeConstants.secondsInOneDay)
            return currentDate > createdAt.addingTimeInterval(interval)
        case .date(let date):
            return currentDate > date
        case .expired:
            return true
        }
    }
}

extension ExpirationPolicy {
    static let never = ExpirationPolicy(rule: .never)
    static func days(_ days: Int) -> ExpirationPolicy {
        ExpirationPolicy(rule: .days(days))
    }
    static func date(_ date: Date) -> ExpirationPolicy {
        ExpirationPolicy(rule: .date(date))
    }
    static let expired = ExpirationPolicy(rule: .expired)
}
