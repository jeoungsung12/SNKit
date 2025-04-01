//
//  DiskStorage.swift
//  SNKit
//
//  Created by 정성윤 on 4/1/25.
//

import UIKit

//파일매니저에서의 작업은 스레드 세이프 하지 않다. -> Lock 필요
final class DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let lock = NSLock()
    private let capacity: Int
    private let expirationInterval: TimeInterval
    
    init(
        directory: URL?,
        capacity: Int,
        expirationInterval: TimeInterval
    ) {
        let cacheDirectory = directory ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cacheDirectory
        self.capacity = capacity
        self.expirationInterval = expirationInterval
        
        //TODO: 디렉토리가 없을 경우에는 생성하는 로직 필요
    }
    
    func store(_ cacheable: Cacheable) {
        //png 데이터로? jpeg 데이터로?
        guard let image = cacheable.image, let data = image.jpegData(compressionQuality: 0.8) else { return }
        let key = cacheable.identifier
        
        lock.lock()
        defer { lock.unlock() }
        
        do {
            try data.write(to: <#T##URL#>)
        } catch {
            //TODO: 로그 찍기
        }
    }
    
    func retrieve(with identifier: String) -> UIImage? {
        //파일 존재 확인
        //만료 확인 -> 만료 파일 삭제
        //이미지 로드
    }
    
    func remove(with identifier: String) {
        
    }
    
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        
        try? fileManager.removeItem(at: cacheDirectory)
        //TODO: Directory 생성
    }
    
    //MARK: - Private Methods
}
