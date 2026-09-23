import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  Future<String> uploadFile({
    required String path,
    required File file,
  }) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteFile({required String path}) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return StorageService(storage);
});
