import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_lifecycle_observer.dart';
import '../../features/authentication/providers/auth_state_provider.dart';
import '../../features/authentication/providers/auth_provider.dart';

final lifecycleObserverProvider = Provider<AppLifecycleObserver?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) =>
        user != null ? AppLifecycleObserver(ref.read(authProvider)) : null,
    loading: () => null,
    error: (_, __) => null,
  );
});
