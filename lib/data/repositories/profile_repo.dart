import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_profile.dart';
import '../../core/services/storage_service.dart';

abstract class ProfileRepositoryBase {
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile profile);
}

final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return StorageService.create();
});

final profileRepositoryProvider = Provider<ProfileRepositoryBase>((ref) {
  final storage = ref.watch(storageServiceProvider.future);
  return ProfileRepository(ref, storage);
});

class ProfileRepository implements ProfileRepositoryBase {
  ProfileRepository(this._ref, this._storageFuture);

  final Ref _ref;
  final Future<StorageService> _storageFuture;

  @override
  Future<UserProfile?> getProfile() async {
    final storage = await _storageFuture;
    return storage.readProfile();
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final storage = await _storageFuture;
    await storage.saveProfile(profile);
    _ref.invalidate(profileNotifierProvider);
  }
}

final profileNotifierProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile();
});
