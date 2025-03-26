import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social_app/core/core.dart';
import '../../../core/enums/post_type.dart';
import '../../../core/enums/content_type.dart';
import '../../../features/notification/repository/notification_repository.dart';
import '../../../features/authentication/models/user_model.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/like_model.dart';
import '../../../core/services/fcm_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

class PostRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationRepository _notificationRepository;
  final MediaService _mediaService = MediaService();
  final Ref? _ref;
  static const int pageSize = 15;

  PostRepository({
    FirebaseFirestore? firestore,
    NotificationRepository? notificationRepository,
    Ref? ref,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationRepository =
            notificationRepository ?? NotificationRepository(),
        _ref = ref {
    logInfo(LogService.POST, '[POST_REPOSITORY] Repository được khởi tạo');
  }

  get uuid => null;

  Future<QuerySnapshot<Map<String, dynamic>>> getFeedPosts({
    DocumentSnapshot? lastDocument,
    PostType? type,
    String? userId,
  }) async {
    final String filters = [
      type != null ? 'loại=${type.value}' : 'tất cả loại',
      userId != null ? 'userId=$userId' : 'tất cả người dùng'
    ].join(', ');

    logInfo(LogService.POST, '[POST_REPOSITORY] Lấy feed posts: $filters');

    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection('posts').orderBy('createdAt', descending: true);

      if (type != null) {
        if (type == PostType.video) {
          // Video feed: hiển thị bài viết có video
          query = query.where('postType', isEqualTo: PostType.video.value);
        } else if (type == PostType.image) {
          // Main feed: hiển thị bài viết text hoặc image
          query = query.where('postType',
              whereIn: [PostType.image.value, PostType.text.value]);
        }
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      // Luôn sử dụng pageSize cố định
      query = query.limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
        logDebug(LogService.POST,
            '[POST_REPOSITORY] Sử dụng phân trang với lastDocument');
      }

      final result = await query.get();
      logDebug(LogService.POST,
          '[POST_REPOSITORY] Đã lấy ${result.docs.length} bài viết');
      return result;
    } catch (e) {
      logError(LogService.POST, '[POST_REPOSITORY] Lỗi khi lấy feed posts: $e',
          e, StackTrace.current);
      throw Exception('Không thể tải bài viết: $e');
    }
  }

  Future<String> createPost({
    required String content,
    required PostType postType,
    List<File>? files,
    Function(double)? onProgress,
  }) async {
    logInfo(LogService.POST,
        '[POST_REPOSITORY] Tạo bài viết mới: loại=${postType.value}, ${files?.length ?? 0} files');

    try {
      final user = _auth.currentUser;

      if (user == null) {
        logError(LogService.POST, '[POST_REPOSITORY] Người dùng chưa đăng nhập',
            null, StackTrace.current);
        throw Exception('Người dùng chưa đăng nhập');
      }

      final postId = const Uuid().v4();
      List<String>? fileUrls;
      String? thumbnailUrl;

      if (files != null && files.isNotEmpty) {
        // Nén media trước khi tải lên
        files = await _processMediaFiles(files, postType, onProgress);

        // Xác định loại file dựa trên MIME type
        final String filePath = files.first.path;
        final String? mimeType = lookupMimeType(filePath);
        logDebug(LogService.POST,
            '[POST_REPOSITORY] File: mimeType=$mimeType, postType=${postType.value}');

        bool isValidFile = false;

        switch (postType) {
          case PostType.image:
            isValidFile = mimeType?.startsWith('image/') == true;
            break;
          case PostType.video:
            isValidFile = mimeType?.startsWith('video/') == true;
            break;
          case PostType.text:
            logError(
                LogService.POST,
                '[POST_REPOSITORY] Không thể đính kèm file cho bài viết dạng text',
                null,
                StackTrace.current);
            throw Exception('Không thể đính kèm file cho bài viết dạng text');
        }

        if (!isValidFile) {
          logError(
              LogService.POST,
              '[POST_REPOSITORY] File không hợp lệ cho loại bài viết ${postType.value}',
              null,
              StackTrace.current);
          throw Exception('File không phù hợp với loại bài viết đã chọn');
        }

        // Tải các file lên Firebase Storage và lấy URL
        logInfo(LogService.POST, '[POST_REPOSITORY] Tải files lên storage');
        final uploadResults = await _mediaService.uploadMultipleFiles(
          files: files,
          basePath: 'posts/$postId/files',
          onProgress: onProgress,
        );

        // Lấy danh sách các URL từ kết quả tải lên
        fileUrls = uploadResults
            .where((result) => result.isSuccess && result.downloadUrl != null)
            .map((result) => result.downloadUrl!)
            .toList();

        logInfo(LogService.POST,
            '[POST_REPOSITORY] Đã tải ${fileUrls.length} files thành công');

        // Nếu là video, tạo thumbnail
        if (postType == PostType.video) {
          logDebug(
              LogService.POST, '[POST_REPOSITORY] Xử lý thumbnail cho video');
          final File videoFile = files.first; // Giả sử chỉ có 1 video

          // Bước 1: Tạo thumbnail
          final File? thumbnailFile = await _mediaService.getVideoThumbnail(
            videoFile.path,
            quality: 80,
            onError: (e) {
              logError(
                  LogService.POST,
                  '[POST_REPOSITORY] Lỗi tạo thumbnail: $e',
                  e,
                  StackTrace.current);
              throw Exception('Lỗi tạo thumbnail: $e');
            },
          );

          if (thumbnailFile == null) {
            logError(
                LogService.POST,
                '[POST_REPOSITORY] Không thể tạo thumbnail từ video',
                null,
                StackTrace.current);
            throw Exception('Không thể tạo thumbnail từ video.');
          }

          // Bước 2: Tải lên thumbnail
          final uploadResult = await _mediaService.uploadSingleFile(
            file: thumbnailFile,
            path:
                'posts/$postId/thumbnails/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          if (!uploadResult.isSuccess || uploadResult.downloadUrl == null) {
            throw Exception('Không thể tải lên thumbnail.');
          }

          thumbnailUrl = uploadResult.downloadUrl;
          logDebug(LogService.POST,
              '[POST_REPOSITORY] Thumbnail đã được tạo và tải lên');
        }
      } else if (postType != PostType.text) {
        throw Exception(
            'Cần đính kèm file cho bài viết dạng ${postType.value}');
      }

      // Tạo bài viết
      final post = PostModel(
        postId: postId,
        userId: user.uid,
        content: content,
        fileUrls: fileUrls,
        thumbnailUrl: thumbnailUrl,
        postType: postType,
        createdAt: DateTime.now(),
        likeCount: 0,
        commentCount: 0,
      );

      await _firestore.collection('posts').doc(postId).set(post.toMap());
      logInfo(LogService.POST,
          '[POST_REPOSITORY] Đã tạo bài viết thành công: ID=$postId');

      return postId;
    } catch (e) {
      logError(LogService.POST, '[POST_REPOSITORY] Lỗi khi tạo bài viết: $e', e,
          StackTrace.current);
      throw Exception('Không thể tạo bài viết: $e');
    }
  }

  Future<void> updatePost({
    required String postId,
    required String content,
    required PostType postType,
    List<File>? newFiles,
    List<String>? deletedFileUrls,
    Function(double)? onProgress,
  }) async {
    logInfo(LogService.POST,
        '[POST_REPOSITORY] Cập nhật bài viết ID: $postId, loại=${postType.value}');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Người dùng chưa đăng nhập khi cập nhật bài viết',
            null,
            StackTrace.current);
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Lấy thông tin bài viết hiện tại
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Không tìm thấy bài viết ID: $postId',
            null,
            StackTrace.current);
        throw Exception('Không tìm thấy bài viết');
      }

      final currentPost =
          PostModel.fromMap({...postDoc.data()!, 'postId': postDoc.id});

      // Kiểm tra quyền chỉnh sửa
      if (currentPost.userId != user.uid) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Không có quyền chỉnh sửa bài viết',
            null,
            StackTrace.current);
        throw Exception('Bạn không có quyền chỉnh sửa bài viết này');
      }

      List<String>? fileUrls = currentPost.fileUrls;
      String? thumbnailUrl = currentPost.thumbnailUrl;
      int filesChanged = 0;

      // Xóa các file đã chọn để xóa
      if (deletedFileUrls != null && deletedFileUrls.isNotEmpty) {
        filesChanged += deletedFileUrls.length;
        logDebug(LogService.POST,
            '[POST_REPOSITORY] Xóa ${deletedFileUrls.length} files');
        fileUrls?.removeWhere((url) => deletedFileUrls.contains(url));
      }

      // Upload các file mới
      if (newFiles != null && newFiles.isNotEmpty) {
        filesChanged += newFiles.length;
        // Nén media trước khi tải lên
        newFiles = await _processMediaFiles(newFiles, postType, onProgress);

        // Xác định loại file dựa trên MIME type
        final String filePath = newFiles.first.path;
        final String? mimeType = lookupMimeType(filePath);
        bool isValidFile = false;

        switch (postType) {
          case PostType.image:
            isValidFile = mimeType?.startsWith('image/') == true;
            break;
          case PostType.video:
            isValidFile = mimeType?.startsWith('video/') == true;
            break;
          case PostType.text:
            logError(
                LogService.POST,
                '[POST_REPOSITORY] Không thể đính kèm file cho bài viết dạng text',
                null,
                StackTrace.current);
            throw Exception('Không thể đính kèm file cho bài viết dạng text');
        }

        if (!isValidFile) {
          logError(
              LogService.POST,
              '[POST_REPOSITORY] File không hợp lệ cho loại bài viết ${postType.value}',
              null,
              StackTrace.current);
          throw Exception('File không phù hợp với loại bài viết đã chọn');
        }

        // Tải các file mới lên Firebase Storage
        logDebug(LogService.POST,
            '[POST_REPOSITORY] Tải ${newFiles.length} files mới lên storage');
        final uploadResults = await _mediaService.uploadMultipleFiles(
          files: newFiles,
          basePath: 'posts/$postId/files',
          onProgress: onProgress,
        );

        // Lấy danh sách các URL từ kết quả tải lên
        final newFileUrls = uploadResults
            .where((result) => result.isSuccess && result.downloadUrl != null)
            .map((result) => result.downloadUrl!)
            .toList();

        fileUrls = [...?fileUrls, ...newFileUrls];
      }

      // Cập nhật bài viết
      await _firestore.collection('posts').doc(postId).update({
        'content': content,
        'postType': postType.value,
        'fileUrls': fileUrls,
        'thumbnailUrl': thumbnailUrl,
        'updatedAt': DateTime.now(),
      });

      logInfo(
          LogService.POST, '[POST_REPOSITORY] Đã cập nhật bài viết thành công');
    } catch (e) {
      logError(
          LogService.POST,
          '[POST_REPOSITORY] Lỗi khi cập nhật bài viết: $e',
          e,
          StackTrace.current);
      throw Exception('Không thể cập nhật bài viết: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    logInfo(LogService.POST, '[POST_REPOSITORY] Xóa bài viết ID: $postId');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Người dùng chưa đăng nhập khi xóa bài viết',
            null,
            StackTrace.current);
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Lấy thông tin bài viết
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Không tìm thấy bài viết ID: $postId',
            null,
            StackTrace.current);
        throw Exception('Không tìm thấy bài viết');
      }

      final post =
          PostModel.fromMap({...postDoc.data()!, 'postId': postDoc.id});

      // Kiểm tra quyền xóa
      if (post.userId != user.uid) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Người dùng không có quyền xóa bài viết này',
            null,
            StackTrace.current);
        throw Exception('Bạn không có quyền xóa bài viết này');
      }

      // Xóa bài viết
      await _firestore.collection('posts').doc(postId).delete();
      logDebug(LogService.POST,
          '[POST_REPOSITORY] Đã xóa document bài viết từ Firestore');

      // Xóa các file đính kèm
      int filesDeleted = 0;
      if (post.fileUrls != null && post.fileUrls!.isNotEmpty) {
        logDebug(LogService.POST,
            '[POST_REPOSITORY] Xóa ${post.fileUrls!.length} files đính kèm');
        for (final fileUrl in post.fileUrls!) {
          await deleteFileFromFirebase(fileUrl);
          filesDeleted++;
        }
      }

      // Xóa thumbnail nếu có
      if (post.thumbnailUrl != null) {
        await deleteFileFromFirebase(post.thumbnailUrl!);
        filesDeleted++;
      }

      logInfo(LogService.POST,
          '[POST_REPOSITORY] Đã xóa bài viết thành công: $filesDeleted files liên quan');
    } catch (e) {
      logError(LogService.POST, '[POST_REPOSITORY] Lỗi khi xóa bài viết: $e', e,
          StackTrace.current);
      throw Exception('Không thể xóa bài viết: $e');
    }
  }

  Future<void> deleteFileFromFirebase(String fileUrl) async {
    logDebug(LogService.POST, '[POST_REPOSITORY] Xóa file: $fileUrl');
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      logDebug(LogService.POST, '[POST_REPOSITORY] File đã xóa thành công');
    } catch (e) {
      logError(LogService.POST, '[POST_REPOSITORY] Lỗi khi xóa file: $e', e,
          StackTrace.current);
      throw Exception('Lỗi khi xóa file: $e');
    }
  }

  /// Lấy danh sách comments của một bài viết
  Future<QuerySnapshot<Map<String, dynamic>>> getComments({
    required String postId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    logInfo(LogService.POST,
        '[POST_REPOSITORY] Lấy comments cho bài viết ID: $postId, limit: $limit');

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
        logDebug(LogService.POST,
            '[POST_REPOSITORY] Sử dụng phân trang với lastDocument');
      }

      final result = await query.get();
      logDebug(LogService.POST,
          '[POST_REPOSITORY] Đã lấy ${result.docs.length} comments');
      return result;
    } catch (e) {
      logError(LogService.POST, '[POST_REPOSITORY] Lỗi khi lấy comments: $e', e,
          StackTrace.current);
      throw Exception('Không thể lấy comments: $e');
    }
  }

  /// Tạo comment mới
  Future<String> createComment({
    required String postId,
    required String content,
  }) async {
    logInfo(LogService.POST,
        '[POST_REPOSITORY] Tạo comment cho bài viết ID: $postId');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Người dùng chưa đăng nhập khi tạo comment',
            null,
            StackTrace.current);
        throw Exception('Người dùng chưa đăng nhập');
      }

      final commentId = const Uuid().v4();
      final comment = CommentModel(
        commentId: commentId,
        postId: postId,
        userId: user.uid,
        content: content,
        createdAt: DateTime.now(),
      );

      final batch = _firestore.batch();
      // Thêm comment và cập nhật số lượng comment
      batch.set(
        _firestore.collection('comments').doc(commentId),
        comment.toMap(),
      );
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'commentCount': FieldValue.increment(1)},
      );

      await batch.commit();
      logDebug(
          LogService.POST, '[POST_REPOSITORY] Đã lưu comment ID: $commentId');

      // Lấy thông tin bài viết để gửi thông báo
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final post =
            PostModel.fromMap({...postDoc.data()!, 'postId': postDoc.id});

        // Chỉ tạo thông báo nếu người bình luận không phải là chủ bài viết
        if (post.userId != user.uid) {
          // Lấy thông tin người dùng hiện tại để tạo thông báo
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          final userData = userDoc.data() ?? {};
          final currentUser = UserModel(
            uid: user.uid,
            email: userData['email'] ?? '',
            fullName: userData['fullName'] ?? 'Người dùng',
            profileImage: userData['profileImage'],
          );

          // Tạo thông báo comment
          logInfo(LogService.POST,
              '[POST_REPOSITORY] Gửi thông báo comment đến ${post.userId}');
          await _notificationRepository.createCommentNotification(
            receiverId: post.userId,
            sender: currentUser,
            postId: postId,
            commentId: commentId,
          );
        }
      }

      return commentId;
    } catch (e) {
      logError(LogService.POST, '[POST_REPOSITORY] Lỗi khi tạo comment: $e', e,
          StackTrace.current);
      rethrow;
    }
  }

  /// Xóa comment
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    logInfo(LogService.POST,
        '[POST_REPOSITORY] Xóa comment ID: $commentId từ bài viết ID: $postId');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Người dùng chưa đăng nhập khi xóa comment',
            null,
            StackTrace.current);
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Kiểm tra quyền xóa comment
      final commentDoc =
          await _firestore.collection('comments').doc(commentId).get();

      if (!commentDoc.exists) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Không tìm thấy comment ID: $commentId',
            null,
            StackTrace.current);
        throw Exception('Không tìm thấy bình luận');
      }

      final commentUserId = commentDoc.data()!['userId'];
      if (commentUserId != user.uid) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Không có quyền xóa comment (userId khác commentUserId)',
            null,
            StackTrace.current);
        throw Exception('Bạn không có quyền xóa bình luận này');
      }

      // Sử dụng batch để xóa comment và cập nhật số lượng
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('comments').doc(commentId));
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'commentCount': FieldValue.increment(-1)},
      );

      await batch.commit();
      logInfo(LogService.POST, '[POST_REPOSITORY] Đã xóa comment thành công');
    } catch (e) {
      logError(LogService.POST, '[POST_REPOSITORY] Lỗi khi xóa comment: $e', e,
          StackTrace.current);
      throw Exception('Không thể xóa comment: $e');
    }
  }

  /// Kiểm tra trạng thái like của một hoặc nhiều content
  Future<Map<String, bool>> getLikeStatus({
    required List<String> contentIds,
  }) async {
    logInfo(LogService.POST,
        '[POST_REPOSITORY] Kiểm tra trạng thái like cho ${contentIds.length} contentIds');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Người dùng chưa đăng nhập khi kiểm tra like',
            null,
            StackTrace.current);
        throw Exception('Người dùng chưa đăng nhập');
      }

      final Map<String, bool> results = {for (var id in contentIds) id: false};

      final futures = contentIds.map((contentId) async {
        final likeId = "${user.uid}_$contentId";
        final doc = await _firestore.collection('likes').doc(likeId).get();
        return doc.exists;
      }).toList();

      final statuses = await Future.wait(futures);

      for (var i = 0; i < contentIds.length; i++) {
        results[contentIds[i]] = statuses[i];
      }

      logDebug(LogService.POST,
          '[POST_REPOSITORY] Kết quả kiểm tra like: ${results.values.where((v) => v).length}/${results.length} đã like');
      return results;
    } catch (e) {
      logError(
          LogService.POST,
          '[POST_REPOSITORY] Lỗi khi kiểm tra trạng thái like: $e',
          e,
          StackTrace.current);
      throw Exception('Không thể kiểm tra trạng thái like: $e');
    }
  }

  /// Toggle like với optimistic update
  Future<void> toggleLike(String contentId, ContentType contentType) async {
    logInfo(LogService.POST,
        '[POST_REPOSITORY] Toggle like: contentId=$contentId, loại=${contentType.name}');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        logError(
            LogService.POST,
            '[POST_REPOSITORY] Người dùng chưa đăng nhập khi thực hiện like',
            null,
            StackTrace.current);
        throw Exception('Người dùng chưa đăng nhập');
      }

      final likeId = "${user.uid}_$contentId";
      final likeRef = _firestore.collection('likes').doc(likeId);

      // Xác định collection name dựa trên content type
      String collectionName;
      switch (contentType) {
        case ContentType.post:
          collectionName = 'posts';
          break;
        case ContentType.comment:
          collectionName = 'comments';
          break;
        case ContentType.story:
          collectionName = 'stories';
          break;
      }

      final contentRef = _firestore.collection(collectionName).doc(contentId);

      // Kiểm tra trực tiếp document thay vì gọi getLikeStatus
      final likeDoc = await likeRef.get();
      final isLiked = likeDoc.exists;

      final batch = _firestore.batch();

      if (isLiked) {
        // Unlike
        batch.delete(likeRef);
        batch.update(contentRef, {'likeCount': FieldValue.increment(-1)});
        logDebug(LogService.POST, '[POST_REPOSITORY] Thực hiện unlike');
      } else {
        // Like
        final like = LikeModel(
          likeId: likeId,
          contentId: contentId,
          contentType: contentType,
          userId: user.uid,
          createdAt: DateTime.now(),
        );
        batch.set(likeRef, like.toMap());
        batch.update(contentRef, {'likeCount': FieldValue.increment(1)});
        logDebug(LogService.POST, '[POST_REPOSITORY] Thực hiện like');

        // Tạo thông báo nếu là like post và không phải của chính mình
        if (contentType == ContentType.post) {
          final postDoc = await contentRef.get();
          if (postDoc.exists) {
            final post =
                PostModel.fromMap({...postDoc.data()!, 'postId': postDoc.id});

            if (post.userId != user.uid) {
              // Lấy thông tin người dùng hiện tại để tạo thông báo
              final userDoc =
                  await _firestore.collection('users').doc(user.uid).get();
              final userData = userDoc.data() ?? {};
              final currentUser = UserModel(
                uid: user.uid,
                email: userData['email'] ?? '',
                fullName: userData['fullName'] ?? 'Người dùng',
                profileImage: userData['profileImage'],
              );

              // Tạo thông báo like
              logInfo(LogService.POST,
                  '[POST_REPOSITORY] Gửi thông báo like đến ${post.userId}');
              await _notificationRepository.createLikeNotification(
                receiverId: post.userId,
                sender: currentUser,
                postId: contentId,
              );

              // Gửi thông báo FCM nếu có token
              final receiverDoc =
                  await _firestore.collection('users').doc(post.userId).get();
              final receiverData = receiverDoc.data();
              final receiverToken = receiverData?['fcmToken'] as String?;

              if (receiverToken != null && _ref != null) {
                final fcmService = _ref?.read(fcmServiceProvider);
                if (fcmService != null) {
                  await fcmService.sendLikeNotification(
                    receiverToken: receiverToken,
                    senderName: currentUser.fullName,
                    senderId: currentUser.uid,
                    postId: contentId,
                    senderAvatar: currentUser.profileImage,
                  );
                }
              }
            }
          }
        }
      }

      await batch.commit();
      logInfo(LogService.POST,
          '[POST_REPOSITORY] Toggle like hoàn tất: ${isLiked ? "unlike" : "like"}');
    } catch (e) {
      logError(
          LogService.POST,
          '[POST_REPOSITORY] Lỗi khi thực hiện toggle like: $e',
          e,
          StackTrace.current);
      throw Exception('Không thể thực hiện thao tác like: $e');
    }
  }

  /// Lấy thông tin bài viết theo ID
  Future<PostModel?> getPostById(String postId) async {
    logInfo(LogService.POST,
        '[POST_REPOSITORY] Lấy thông tin bài viết ID: $postId');

    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();

      if (!postDoc.exists) {
        logDebug(LogService.POST,
            '[POST_REPOSITORY] Không tìm thấy bài viết ID: $postId');
        return null;
      }

      final post =
          PostModel.fromMap({...postDoc.data()!, 'postId': postDoc.id});
      return post;
    } catch (e) {
      logError(
          LogService.POST,
          '[POST_REPOSITORY] Lỗi khi lấy thông tin bài viết: $e',
          e,
          StackTrace.current);
      throw Exception('Không thể lấy thông tin bài viết: $e');
    }
  }

  Future<List<File>> _processMediaFiles(
    List<File> files,
    PostType postType,
    Function(double)? onProgress,
  ) async {
    logInfo(LogService.POST,
        '[POST_REPOSITORY] Xử lý ${files.length} media files cho loại ${postType.value}');

    try {
      final List<Future<File?>> compressionTasks = [];
      final List<int> indices = [];

      // Tạo danh sách các task nén đồng thời
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final mediaType = _mediaService.detectMediaType(file);

        Future<File?> task;
        if (mediaType == MediaType.image) {
          task = _mediaService.compressImage(
            file,
            onError: (e) {
              logError(LogService.POST, '[POST_REPOSITORY] Lỗi nén ảnh', e,
                  StackTrace.current);
            },
          );
        } else if (mediaType == MediaType.video) {
          task = _mediaService.compressVideo(
            file,
            onProgress: (videoProgress) {
              if (onProgress != null) {
                onProgress(videoProgress);
              }
            },
            onError: (e) {
              logError(LogService.POST, '[POST_REPOSITORY] Lỗi nén video', e,
                  StackTrace.current);
            },
          );
        } else {
          task = Future.value(file);
        }

        compressionTasks.add(task);
        indices.add(i);
      }

      // Theo dõi tiến trình tổng thể
      if (onProgress != null) {
        int completed = 0;
        for (int i = 0; i < compressionTasks.length; i++) {
          compressionTasks[i] = compressionTasks[i].then((result) {
            completed++;
            onProgress(completed / files.length);
            return result;
          });
        }
      }

      // Chờ tất cả các task hoàn thành
      final results = await Future.wait(compressionTasks);

      // Tạo danh sách kết quả
      final List<File> processedFiles = List.filled(files.length, files.first);
      for (int i = 0; i < results.length; i++) {
        final index = indices[i];
        processedFiles[index] = results[i] ?? files[index];
      }

      logDebug(LogService.POST,
          '[POST_REPOSITORY] Hoàn tất xử lý ${processedFiles.length} media files');
      return processedFiles;
    } catch (e) {
      logError(LogService.POST, '[POST_REPOSITORY] Lỗi khi xử lý media: $e', e,
          StackTrace.current);
      return files;
    }
  }
}
