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
    
    static func createMockSession() -> MockURLSession {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        object_setClass(session, MockURLSession.self)
        
        let mockSession = session as! MockURLSession
        return mockSession
    }
    
    override func dataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        let task = MockDataTask.createMockTask()
        (task as! MockDataTask).configure(mockData: mockData,
                                          mockResponse: mockResponse,
                                          mockError: mockError,
                                          completionHandler: completionHandler)
        return task
    }
    
    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        let task = MockDataTask.createMockTask()
        (task as! MockDataTask).configure(mockData: mockData,
                                          mockResponse: mockResponse,
                                          mockError: mockError,
                                          completionHandler: completionHandler)
        return task
    }
}

final class MockDataTask: URLSessionDataTask, @unchecked Sendable {
    private var mockData: Data?
    private var mockResponse: URLResponse?
    private var mockError: Error?
    private var taskCompletionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    
    static func createMockTask() -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!) { _, _, _ in }
        object_setClass(task, MockDataTask.self)
        return task as! MockDataTask
    }
    
    func configure(
        mockData: Data?,
        mockResponse: URLResponse?,
        mockError: Error?,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        self.mockData = mockData
        self.mockResponse = mockResponse
        self.mockError = mockError
        self.taskCompletionHandler = completionHandler
    }
    
    override func resume() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self, let completionHandler = self.taskCompletionHandler else { return }
            completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
    }
}
