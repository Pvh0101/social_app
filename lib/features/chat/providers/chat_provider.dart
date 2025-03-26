import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/chat_repository.dart';

final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth.currentUser == null) throw Exception('Chưa đăng nhập');

  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    currentUserId: auth.currentUser!.uid,
  );
});
