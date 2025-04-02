//
//  DiskStorage.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

//파일매니저에서의 작업은 스레드 세이프 하지 않다. -> Lock 필요?
final class DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let lock = NSLock()
    private let capacity: Int
    private let expirationPolicy: ExpirationPolicy
    
    init(
        directory: URL?,
        capacity: Int,
        expirationPolicy: ExpirationPolicy
    ) {
        let cacheDirectory = directory ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cacheDirectory
        self.capacity = capacity
        self.expirationPolicy = expirationPolicy
        
        //디렉토리가 없을 경우 생성
        createDirectoryIfNeed()
    }
    
    func store(_ cacheable: Cacheable) {
        //png 데이터로? jpeg 데이터로?
        guard let image = cacheable.image, let data = image.jpegData(compressionQuality: 0.8) else { return }
        let key = cacheable.identifier
        let fileURL = cacheURL(for: key)
        
        lock.lock()
        defer { lock.unlock() }
        
        do {
            //생성시간, 이테그
            var metaData: [String:Any] = [
                "createdAt": Date().timeIntervalSince1970
            ]
            if let eTag = cacheable.eTag {
                metaData["eTag"] = eTag
            }
            
            let metadataURL = fileURL.appendingPathExtension("metadata")
            let metadataData = try JSONSerialization.data(withJSONObject: metaData, options: [])
            try metadataData.write(to: metadataURL)
            
            //이미지 데이터를 저장
            try data.write(to: fileURL)
            
            //용량 체크 넘으면 -> 삭제
            removeFilesIfNeeded()
        } catch {
            print("디스크 캐시 저장 실패")
        }
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        let fileURL = cacheURL(for: identifier)
        let metadataURL = fileURL.appendingPathExtension("metadata")
        
        lock.lock()
        defer { lock.unlock() }
        
        //파일이 디스크에 존재하는지?
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        if let metadata = try? Data(contentsOf: metadataURL),
           let info = try? JSONSerialization.jsonObject(with: metadata, options: []) as? [String:Any],
           let createdAt = info["createdAt"] as? TimeInterval {
            
            let creationDate = Date(timeIntervalSince1970: createdAt)
            let currentDate = Date()
            
            if expirationPolicy.isExpired(createdAt: creationDate, currentDate: currentDate) {
                try? fileManager.removeItem(at: fileURL)
                try? fileManager.removeItem(at: metadataURL)
                return nil
            }
            
            //TODO: 접근시간 업데이트 (알고리즘 LRU)
            updateAccessTime(for: metadataURL, info: info)
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            print("디스크 이미지 로딩 실패!")
            return nil
        }
    }
    
    private func updateAccessTime(for metadataURL: URL, info: [String: Any]) {
        var updatedInfo = info
        updatedInfo["lastAccessedAt"] = Date().timeIntervalSince1970
        
        do {
            let metadataData = try JSONSerialization.data(withJSONObject: updatedInfo, options: [])
            try metadataData.write(to: metadataURL)
        } catch {
            print("메타데이터 업데이트 실패")
        }
    }
    
    func retrieveCacheable(with identifier: String) -> Cacheable? {
        guard let image = retrieve(with: identifier),
           let url = URL(string: identifier) else {
            return nil
        }
        
        let metadataURL = cacheURL(for: identifier).appendingPathExtension("metadata")
        var eTag: String? = nil
        
        if let metadata = try? Data(contentsOf: metadataURL),
           let info = try? JSONSerialization.jsonObject(with: metadata, options: []) as? [String:Any] {
            eTag = info["eTag"] as? String
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
        // 파일 이름 충돌을 방지하기 위해 해시 값 사용 -> 이게 sha256같은건가?
        let hashedKey = key.hashValue
        return cacheDirectory.appendingPathComponent("\(hashedKey)", isDirectory: false)
    }
    
    private func createDirectoryIfNeed() {
        lock.lock()
        defer { lock.unlock() }
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("캐시 디렉토리 생성 에러")
            }
        }
    }
    
    private func removeFilesIfNeeded() {
        //현재 캐시의 크기가 용량을 초과한다면? 가장 오래된 것부터 삭제할것
        let fileURLs = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: [])
        guard let files = fileURLs else { return }
        
        var totalSize: Int = 0
        var fileAttributes: [[String:Any]] = []
        
        for fileURL in files {
            
            if fileURL.pathExtension == "metadata" {
                continue
            }
            
            if let attributes = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
               let fileSize = attributes.fileSize,
               let modificationDate = attributes.contentModificationDate {
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
        
        //TODO: LRU
        if totalSize > capacity {
            let sortedFiles = fileAttributes.sorted { (file1, file2) -> Bool in
                return (file1["date"] as! Date) < (file2["date"] as! Date)
            }
            
            var currentSize = totalSize
            for file in sortedFiles {
                if currentSize <= capacity * 8 / 10 { // -> 80프로 줄이기?
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
