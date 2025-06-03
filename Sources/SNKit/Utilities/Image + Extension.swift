//
//  Image + Extension.swift
//  SNKit
//
//  Created by 정성윤 on 4/23/25.
//

import SwiftUI
import Combine

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

public struct SNImage: View {
    private let url: URL
    private let headers: RequestHeaders?
    private let cacheOption: CacheOption
    private let storageOption: StorageOption
    private let processingOption: ImageProcessingOption
    
    @State private var image: UIImage?
    @State private var isLoading: Bool = true
    @State private var loadError: Error?
    @State private var currentTask: ImageLoadingTask?
    @State private var lastURL: URL?
    
    public init(
        url: URL,
        headers: RequestHeaders? = nil,
        cacheOption: CacheOption = .cacheFirst,
        storageOption: StorageOption = .hybrid,
        processingOption: ImageProcessingOption = .none
    ) {
        self.url = url
        self.headers = headers
        self.cacheOption = cacheOption
        self.storageOption = storageOption
        self.processingOption = processingOption
    }
    
    public var body: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
            } else if loadError != nil {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Color.gray.opacity(0.3)
                    .overlay(
                        ActivityIndicator(isAnimating: $isLoading)
                    )
            }
        }
        .onAppear {
            checkURLChangeAndLoad()
        }
        .onReceive(Just(url)) { _ in
            checkURLChangeAndLoad()
        }
        .onDisappear {
            cancelCurrentTask()
        }
    }
    
    private func checkURLChangeAndLoad() {
        if lastURL != url {
            if lastURL != nil {
                cancelCurrentTask()
                resetState()
            }
            lastURL = url
            loadImage()
        }
    }
    
    private func resetState() {
        isLoading = true
        loadError = nil
        image = nil
    }
    
    private func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    private func loadImage() {
        guard isLoading, image == nil else { return }
        
        cancelCurrentTask()
        
        let task = ImageLoadingTask(url: url)
        currentTask = task
        
        SNKit.shared.loadImage(
            from: url,
            headers: headers,
            cacheOption: cacheOption,
            storageOption: storageOption,
            processingOption: processingOption
        ) { result in
            guard self.currentTask === task, task.isValid else {
                return
            }
            
            switch result {
            case .success(let loadedImage):
                DispatchQueue.main.async {
                    guard self.currentTask === task, task.isValid else {
                        return
                    }
                    
                    self.image = loadedImage
                    self.loadError = nil
                    self.isLoading = false
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    guard self.currentTask === task, task.isValid else {
                        return
                    }
                    
                    self.loadError = error
                    self.isLoading = false
                }
            }
        }
    }
}
