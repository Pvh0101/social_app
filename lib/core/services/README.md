# Các dịch vụ xử lý Media

Thư mục này chứa các dịch vụ liên quan đến việc quản lý, xử lý và tải lên media trong ứng dụng.

## Kiến trúc

Hệ thống xử lý media được tổ chức theo mô hình sau:

1. **MediaService**: Service chính xử lý tất cả các thao tác media (facade)
   - Xử lý chọn media từ camera/gallery
   - Xử lý crop, nén, tạo thumbnail
   - Ủy thác việc tải lên cho MediaUploadService
2. **MediaUploadService**: Service chuyên biệt để tải lên Firebase Storage
3. **MediaTypes**: Định nghĩa các enum và type cho media

## Cách sử dụng

### Chọn ảnh/video

```dart
// Sử dụng Riverpod
final mediaService = ref.read(mediaServiceProvider);

// Chọn ảnh từ camera
final File? imageFile = await mediaService.pickImageFromCamera(
  onError: (error) => print(error),
);

// Chọn nhiều ảnh từ gallery
final List<File> imageFiles = await mediaService.pickImagesFromGallery(
  multiple: true,
  onError: (error) => print(error),
);

// Chọn video
final File? videoFile = await mediaService.pickVideoFromGallery(
  onError: (error) => print(error),
);
```

### Xử lý media

```dart
// Crop ảnh
final File? croppedImage = await mediaService.cropImage(
  imageFile,
  aspectRatio: CropAspectRatioPreset.square,
  lockAspectRatio: true,
);

// Nén ảnh
final File? compressedImage = await mediaService.compressImage(imageFile);

// Tạo thumbnail từ video
final File? thumbnail = await mediaService.getVideoThumbnail(
  videoFile.path,
  quality: 85,
);
```

### Tải lên media

```dart
// Tải lên một file
final uploadResult = await mediaService.uploadSingleFile(
  file: imageFile,
  path: 'images/user_123/profile.jpg',
  onProgress: (progress) {
    print('Tiến trình tải lên: ${(progress * 100).toStringAsFixed(2)}%');
  },
);

if (uploadResult.isSuccess) {
  print('URL tải lên: ${uploadResult.downloadUrl}');
}

// Tải lên nhiều file
final List<UploadResult> results = await mediaService.uploadMultipleFiles(
  files: imageFiles,
  basePath: 'images/user_123/album',
  onProgress: (progress) {
    print('Tiến trình tải lên: ${(progress * 100).toStringAsFixed(2)}%');
  },
);
```

## Lưu ý

1. `MediaService` là lớp chính để làm việc với media, theo mẫu thiết kế Facade.

2. Bạn có thể tiếp cận trực tiếp `MediaUploadService` nếu cần qua provider:

```dart
final uploadService = ref.read(mediaUploadServiceProvider);
```

3. Các chức năng từ MediaPickerService và MediaProcessorService đã được tích hợp vào MediaService để đơn giản hóa cấu trúc. 