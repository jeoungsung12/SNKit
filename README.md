# SNKit

SNKit은 iOS 앱을 위한 효율적인 이미지 캐싱 및 다운로드 라이브러리입니다. 메모리와 디스크 기반의 하이브리드 캐싱 시스템을 통해 이미지 로딩 성능을 최적화하고, 다양한 캐싱 전략과 이미지 처리 옵션을 제공합니다.

## 주요 기능

- **하이브리드 캐싱 시스템**: 메모리와 디스크를 모두 활용한 효율적인 이미지 캐싱
- **ETag 기반 검증**: 서버 이미지 변경 여부를 효율적으로 확인
- **다양한 캐싱 전략**: 캐시 우선, ETag 검증, 강제 다운로드 등 다양한 캐싱 옵션
- **이미지 처리**: 리사이징, 다운샘플링 등 이미지 처리 기능 제공
- **쉬운 사용법**: UIImageView 확장을 통한 간편한 이미지 로딩
- **만료 정책**: 캐시 항목에 대한 다양한 만료 정책 설정 가능
- **커스터마이징**: 메모리 및 디스크 캐시 용량, 만료 정책 등 커스터마이징 가능

## 설치 방법

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/jeoungsung12/SNKit.git", .exact("1.1.0"))
]
```


## 사용 방법

### 기본 사용법

```swift
import SNKit

// UIImageView 확장 사용
imageView.snSetImage(with: imageURL)

// 또는 SNKit 직접 사용
SNKit.shared.loadImage(from: imageURL) { result in
    switch result {
    case .success(let image):
        // 이미지 사용
    case .failure(let error):
        // 에러 처리
    }
}
```

### 캐싱 옵션 설정

```swift
// 캐시 우선 (기본값)
imageView.snSetImage(with: imageURL, cacheOption: .cacheFirst)

// ETag 검증
imageView.snSetImage(with: imageURL, cacheOption: .eTagValidation)

// 강제 다운로드
imageView.snSetImage(with: imageURL, cacheOption: .forceDownload)
```

### 저장 옵션 설정
```swift
// 메모리
imageView.snSetImage(with: url, storageOption: .memory)

// 디스크
imageView.snSetImage(with: url, storageOption: .disk)

// 하이브리드
imageView.snSetImage(with: url, storageOption: .hybrid)
```


### 이미지 처리 옵션

```swift
// 이미지 리사이징
imageView.snSetImage(
    with: imageURL,
    processingOption: .resize(CGSize(width: 100, height: 100))
)

// 다운샘플링 (메모리 사용량 최적화)
imageView.snSetImage(
    with: imageURL,
    processingOption: .downsample(CGSize(width: 100, height: 100))
)
```

### 캐시 관리

```swift
// 특정 URL에 대한 캐시 제거
SNKit.shared.removeCache(for: imageURL)

// 모든 캐시 제거
SNKit.shared.clearCache()

// 메모리 캐시만 제거
SNKit.shared.clearCache(option: .memory)

// 디스크 캐시만 제거
SNKit.shared.clearCache(option: .disk)
```

### 커스텀 설정

```swift
let configuration = Configuration(
    memoryCacheCapacity: 30_000_000,  // 30MB
    diskCacheCapacity: 300_000_000,   // 300MB
    expirationPolicy: .days(3),       // 3일 후 만료
    cacheDirectory: customDirectoryURL // 커스텀 캐시 디렉토리
)

let snkit = SNKit(configuration: configuration)
```

### 만료 정책 설정

```swift
// 만료 없음
let neverExpire = ExpirationPolicy.never

// 일수 기반 만료
let expireAfterDays = ExpirationPolicy.days(7)

// 특정 날짜 만료
let expireOnDate = ExpirationPolicy.date(specificDate)

// 즉시 만료
let expireImmediately = ExpirationPolicy.expired

let config = Configuration(expirationPolicy: expireAfterDays)
```

## 아키텍처

SNKit은 다음과 같은 구성 요소로 이루어져 있습니다:

- **SNKit**: 라이브러리의 메인 진입점
- **CacheManager**: 캐시 전략과 저장소 관리
- **HybridCache**: 메모리와 디스크 캐시를 결합한 하이브리드 캐싱
- **MemoryCache**: 메모리 기반 캐싱 구현 (NSCache 기반)
- **DiskCache**: 디스크 기반 캐싱 구현
- **ImageDownloader**: 이미지 다운로드 및 캐싱 처리
- **ETagHandler**: ETag 기반 이미지 검증
- **ImageProcessor**: 이미지 리사이징 및 다운샘플링 처리

## 요구 사항

- iOS 13.0 이상
- Swift 5.0 이상
