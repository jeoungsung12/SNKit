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
    private let cacheOption: CacheOption
    private let storageOption: StorageOption
    private let processingOption: ImageProcessingOption
    
    @State private var image: UIImage?
    @State private var isLoading: Bool = true
    @State private var loadError: Error?
    
    public init(
        url: URL,
        cacheOption: CacheOption = .cacheFirst,
        storageOption: StorageOption = .hybrid,
        processingOption: ImageProcessingOption = .none
    ) {
        self.url = url
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
        .onAppear(perform: loadImage)
        .onReceive(Just(url)) { newURL in
            if newURL != self.url {
                isLoading = true
                loadError = nil
                image = nil
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard isLoading, image == nil else { return }
        
        SNKit.shared.loadImage(
            from: url,
            cacheOption: cacheOption,
            storageOption: storageOption,
            processingOption: processingOption
        ) { result in
            switch result {
            case .success(let loadedImage):
                self.image = loadedImage
                self.loadError = nil
            case .failure(let error):
                self.loadError = error
            }
            self.isLoading = false
        }
    }
}
