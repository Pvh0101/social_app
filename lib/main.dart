import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/core.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/lifecycle_observer_provider.dart';
import 'core/services/fcm_service.dart';
import 'core/services/firebase/firebase_config_service.dart';
import 'features/authentication/authentication.dart';
import 'features/authentication/presentation/screens/splash_screen.dart';

// Khai báo routeObserver toàn cục
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// Cung cấp route observer thông qua Provider
final routeObserverProvider = Provider<RouteObserver<PageRoute>>((ref) {
  return routeObserver;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Khởi tạo và cấu hình tất cả dịch vụ Firebase
  await FirebaseConfigService().initializeFirebase();

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Khởi tạo FCM Service thông qua provider
  await container.read(fcmServiceProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('vi')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void dispose() {
    // Provider sẽ tự động dispose observer khi cần
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    // Theo dõi observer để dispose khi cần
    ref.listen(lifecycleObserverProvider, (previous, next) {
      previous?.dispose();
    });

    return MaterialApp(
      title: 'Social App',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.themeMode,
      navigatorKey: FCMService.navigatorKey,
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
