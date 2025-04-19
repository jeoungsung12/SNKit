//
//  Logger.swift
//  SNKit
//
//  Created by 정성윤 on 4/19/25.
//

import Foundation
import os.log

final class Logger {
    private let log: OSLog
    
    init(subsystem: String, category: String) {
        self.log = OSLog(subsystem: subsystem, category: category)
    }
    
    func debug(_ message: String) {
        os_log(.debug, log: log, "%{public}@", message)
    }
    
    func info(_ message: String) {
        os_log(.info, log: log, "%{public}@", message)
    }
    
    func warning(_ message: String) {
        os_log(.default, log: log, "%{public}@", message)
    }
    
    func error(_ message: String) {
        os_log(.error, log: log, "%{public}@", message)
    }
    
    func fault(_ message: String) {
        os_log(.fault, log: log, "%{public}@", message)
    }
}
