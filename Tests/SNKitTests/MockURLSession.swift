//
//  File.swift
//  SNKit
//
//  Created by 정성윤 on 4/19/25.
//

import Foundation

final class MockURLSession: URLSession, @unchecked Sendable {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override init() {
        super.init()
    }
    
    override func dataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        return MockDataTask(mockData: mockData, mockResponse: mockResponse, mockError: mockError, completionHandler: completionHandler)
    }
    
    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        return MockDataTask(mockData: mockData, mockResponse: mockResponse, mockError: mockError, completionHandler: completionHandler)
    }
}

final class MockDataTask: URLSessionDataTask, @unchecked Sendable {
    private let mockData: Data?
    private let mockResponse: URLResponse?
    private let mockError: Error?
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    
    init(
        mockData: Data?,
        mockResponse: URLResponse?,
        mockError: Error?,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        self.mockData = mockData
        self.mockResponse = mockResponse
        self.mockError = mockError
        self.completionHandler = completionHandler
    }
    
    override func resume() {
        DispatchQueue.global().async {
            self.completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
    }
}
