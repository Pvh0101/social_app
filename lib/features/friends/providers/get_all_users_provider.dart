import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Provider đơn giản để lấy tất cả users
final getAllUsersProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc['uid'] as String).toList());
});
