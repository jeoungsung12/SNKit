//
//  DiskStorage.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

final class DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let lock = NSLock()
    private let capacity: Int
    private let expirationPolicy: ExpirationPolicy
    private let logger = Logger(subsystem: "com.snkit", category: "DiskCache")
    
    enum DiskCacheError: Error {
        case createDirectoryFailed
        case saveImageFailed
        case saveMetadataFailed
        case loadImageFailed
        case updateMetadataFailed
        case removeFileFailed
    }
    
    init(
        directory: URL?,
        capacity: Int,
        expirationPolicy: ExpirationPolicy
    ) {
        let cacheDirectory = directory ?? fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("SNKitCache", isDirectory: true)
        self.cacheDirectory = cacheDirectory
        self.capacity = capacity
        self.expirationPolicy = expirationPolicy
        
        do {
            try createDirectoryIfNeed()
            logger.info("디스크 캐시 초기화: \(cacheDirectory.path)")
        } catch {
            logger.error("디스크 캐시 생성 실패: \(error.localizedDescription)")
        }
    }
    
    func store(_ cacheable: Cacheable) throws {
        guard let image = cacheable.image, let data = image.jpegData(compressionQuality: 0.8) else {
            throw DiskCacheError.saveImageFailed
        }
        let key = cacheable.identifier
        let fileURL = cacheURL(for: key)
        
        lock.lock()
        defer { lock.unlock() }
        
        do {
            var metaData: [String:Any] = [
                "createdAt": Date().timeIntervalSince1970,
                "lastAccessedAt": Date().timeIntervalSince1970
            ]
            if let eTag = cacheable.eTag {
                metaData["eTag"] = eTag
            }
            
            let metadataURL = fileURL.appendingPathExtension("metadata")
            let metadataData = try JSONSerialization.data(withJSONObject: metaData, options: [])
            
            let directory = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            
            try metadataData.write(to: metadataURL)
            try data.write(to: fileURL)
            
            logger.debug("디스크 캐시에 저장 성공: \(key)")
            
            try removeFilesIfNeeded()
        } catch {
            logger.error("디스크 캐시 저장 실패: \(error.localizedDescription)")
            throw DiskCacheError.saveImageFailed
        }
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        let fileURL = cacheURL(for: identifier)
        let metadataURL = fileURL.appendingPathExtension("metadata")
        
        lock.lock()
        defer { lock.unlock() }
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.debug("디스크 캐시에서 파일을 찾을 수 없음: \(identifier)")
            return nil
        }
        
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            logger.debug("메타데이터를 찾을 수 없음: \(identifier)")
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        do {
            if let metadata = try? Data(contentsOf: metadataURL),
               let info = try? JSONSerialization.jsonObject(with: metadata, options: []) as? [String:Any],
               let createdAt = info["createdAt"] as? TimeInterval {
                
                let creationDate = Date(timeIntervalSince1970: createdAt)
                let currentDate = Date()
                
                if expirationPolicy.isExpired(createdAt: creationDate, currentDate: currentDate) {
                    logger.debug("캐시에서 만료됨: \(identifier)")
                    try? fileManager.removeItem(at: fileURL)
                    try? fileManager.removeItem(at: metadataURL)
                    return nil
                }
                
                try updateAccessTime(for: metadataURL, info: info)
            }
            
            let data = try Data(contentsOf: fileURL)
            guard let image = UIImage(data: data) else {
                logger.error("유효하지 않은 데이터: \(identifier)")
                try fileManager.removeItem(at: fileURL)
                try fileManager.removeItem(at: metadataURL)
                return nil
            }
            
            logger.debug("디스크 캐시 - 이미지 조회 성공: \(identifier)")
            return image
        } catch {
            logger.error("디스크 캐시 - 이미지 조회 실패: \(error.localizedDescription)")
            try? fileManager.removeItem(at: fileURL)
            try? fileManager.removeItem(at: metadataURL)
            return nil
        }
    }
    
    private func updateAccessTime(for metadataURL: URL, info: [String: Any]) throws {
        var updatedInfo = info
        updatedInfo["lastAccessedAt"] = Date().timeIntervalSince1970
        
        do {
            let metadataData = try JSONSerialization.data(withJSONObject: updatedInfo, options: [])
            try metadataData.write(to: metadataURL)
        } catch {
            logger.error("메타데이터 업데이트 실패: \(error.localizedDescription)")
            throw DiskCacheError.updateMetadataFailed
        }
    }
    
    func retrieveCacheable(with identifier: String) -> Cacheable? {
        guard let image = retrieve(with: identifier),
              let url = URL(string: identifier) else {
            logger.error("이미지 조회 실패")
            return nil
        }
        
        let metadataURL = cacheURL(for: identifier).appendingPathExtension("metadata")
        var eTag: String? = nil
        
        if let metadata = try? Data(contentsOf: metadataURL),
           let info = try? JSONSerialization.jsonObject(with: metadata, options: []) as? [String:Any] {
            eTag = info["eTag"] as? String
        } else {
            logger.error("메타데이터 조회 실패")
        }
        
        return CacheableImage(image: image, imageURL: url, identifier: identifier, eTag: eTag)
    }
    
    func remove(with identifier: String) {
        let fileURL = cacheURL(for: identifier)
        let metadataURL = fileURL.appendingPathExtension("metadata")
        
        lock.lock()
        defer { lock.unlock() }
        
        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: metadataURL)
    }
    
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        
        try? fileManager.removeItem(at: cacheDirectory)
        createDirectoryIfNeed()
    }
    
}

extension DiskCache {
    
    private func cacheURL(for key: String) -> URL {
        let hashedKey = "\(key.hashValue)"
        return cacheDirectory.appendingPathComponent(hashedKey, isDirectory: false)
    }
    
    private func createDirectoryIfNeed() throws {
        lock.lock()
        defer { lock.unlock() }
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.error("캐시 디렉토리 생성 에러: \(error.localizedDescription)")
                throw DiskCacheError.createDirectoryFailed
            }
        }
    }
    
    private func removeFilesIfNeeded() {
        let fileURLs = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: []
        )
        guard let files = fileURLs else { return }
        
        var totalSize: Int = 0
        var fileAttributes: [[String:Any]] = []
        
        for fileURL in files {
            if fileURL.pathExtension == "metadata" {
                continue
            }
            
            if let attributes = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = attributes.fileSize {
                totalSize += fileSize
                
                let metadataURL = fileURL.appendingPathExtension("metadata")
                var lastAccessTime: Date = Date.distantPast
                
                if let metadata = try? Data(contentsOf: metadataURL),
                   let info = try? JSONSerialization.jsonObject(with: metadata, options: []) as? [String:Any] {
                    if let accessTime = info["lastAccessedAt"] as? TimeInterval {
                        lastAccessTime = Date(timeIntervalSince1970: accessTime)
                    } else if let createdTime = info["createdAt"] as? TimeInterval {
                        lastAccessTime = Date(timeIntervalSince1970: createdTime)
                    }
                }
                
                fileAttributes.append([
                    "url": fileURL,
                    "size": fileSize,
                    "accessDate": lastAccessTime,
                    "metadataURL": metadataURL
                ])
            }
        }
        
        if totalSize > capacity {
            let sortedFiles = fileAttributes.sorted { (file1, file2) -> Bool in
                return (file1["accessDate"] as! Date) < (file2["accessDate"] as! Date)
            }
            
            var currentSize = totalSize
            for file in sortedFiles {
                if currentSize <= capacity * 8 / 10 {
                    break
                }
                
                if let fileURL = file["url"] as? URL,
                   let metadataURL = file["metadataURL"] as? URL {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        try fileManager.removeItem(at: metadataURL)
                        currentSize -= (file["size"] as? Int) ?? 0
                    } catch {
                        print("캐시 파일 삭제 에러")
                    }
                }
            }
        }
    }
}
