//
//  SNKitTests.swift
//  SNKit
//
//  Created by 정성윤 on 4/19/25.
//

import XCTest
@testable import SNKit

final class SNKitTests: XCTestCase {
    var snkit: SNKit!
    var mockSession: MockURLSession!
    
    override func setUpWithError() throws {
        mockSession = MockURLSession()
        snkit = SNKit(configuration: Configuration(), session: mockSession)
    }
    
    override func tearDownWithError() throws {
        snkit.clearCache()
        snkit = nil
        mockSession = nil
    }
    
    //MARK: CacheFirst
    func testLoadImage_CacheFirst_ReturnsImageFromCache() {
        let expectation = XCTestExpectation(description: "이미지 로드 완료")
        let url = URL(string: "https://example.com/test.jpg")!
        let testImage = UIImage(systemName: "star")!
        
        let cacheable = CacheableImage(image: testImage, imageURL: url)
        snkit.cacheManager.storeImage(with: cacheable)
        
        snkit.loadImage(from: url, cacheOption: .cacheFirst) { result in
            switch result {
            case .success(let image):
                XCTAssertNotNil(image)
                XCTAssertEqual(image.size.width, testImage.size.width)
                XCTAssertEqual(image.size.height, testImage.size.height)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("이미지 로드에 실패했습니다: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    //MARK: ForceDownload
    func testLoadImage_ForceDownload_DownloadsImage() {
        let expectation = XCTestExpectation(description: "이미지 다운로드 완료")
        let url = URL(string: "https://example.com/test.jpg")!
        let testImage = UIImage(systemName: "star")!
        let mockData = testImage.jpegData(compressionQuality: 1.0)!
        
        mockSession.mockResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.mockData = mockData
        
        snkit.loadImage(from: url, cacheOption: .forceDownload) { result in
            switch result {
            case .success(let image):
                XCTAssertNotNil(image)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("이미지 다운로드에 실패했습니다: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    //MARK: ImageProcessor - Resizing
    func testImageProcessing_Resize() {
        let expectation = XCTestExpectation(description: "이미지 처리 완료")
        let url = URL(string: "https://example.com/image.jpg")!
        let testImage = UIImage(systemName: "star")!
        let targetSize = CGSize(width: 50, height: 50)
        
        let cacheable = CacheableImage(image: testImage, imageURL: url)
        snkit.cacheManager.storeImage(with: cacheable)
        
        snkit.loadImage(from: url, processingOption: .resize(targetSize)) { result in
            switch result {
            case .success(let image):
                XCTAssertNotNil(image)
                XCTAssertEqual(image.size.width, targetSize.width)
                XCTAssertEqual(image.size.height, targetSize.height)
                expectation.fulfill()
            case .failure:
                XCTFail("이미지 처리에 실패했습니다")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    //MARK: - Clear Cache
    func testClearCache() {
        let url = URL(string: "https://example.com/image.jpg")!
        let testImage = UIImage(systemName: "star")!
        
        let cacheable = CacheableImage(image: testImage, imageURL: url)
        snkit.cacheManager.storeImage(with: cacheable)
        
        XCTAssertNotNil(snkit.cachedImage(for: url))
        snkit.clearCache()
        XCTAssertNotNil(snkit.cachedImage(for: url))
    }
}
