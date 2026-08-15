import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/emergency_provider.dart';
import 'providers/junction_provider.dart';
import 'providers/live_ambulance_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/driver_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/officer_home_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/ai_service.dart';
import 'services/chat_service.dart';
import 'services/emergency_service.dart';
import 'services/gps_service.dart';
import 'services/junction_service.dart';
import 'services/live_service.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'services/server_config_service.dart';
import 'providers/settings_provider.dart';
import 'widgets/auth_widgets.dart';

import 'core/map_cache.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  // Request permission for iOS (Android 13+ will prompt automatically)
  await FirebaseMessaging.instance.requestPermission();

  await Hive.initFlutter();
  await Hive.openBox('offline_queue');
  await initMapCache();
  final api = ApiService();
  final serverConfig = ServerConfigService();
  api.setBaseUrl(await serverConfig.getApiBaseUrl());
  runApp(AmbulanceApp(api: api, serverConfig: serverConfig));
}

class AmbulanceApp extends StatefulWidget {
  const AmbulanceApp(
      {super.key, required this.api, required this.serverConfig});

  final ApiService api;
  final ServerConfigService serverConfig;

  @override
  State<AmbulanceApp> createState() => _AmbulanceAppState();
}

class _AmbulanceAppState extends State<AmbulanceApp> {
  late final GpsTrackingService _gpsService = GpsTrackingService(widget.api);
  late final _authService = AuthService(widget.api);
  late final LiveService _liveService = LiveService();
  late final _authProvider =
      AuthProvider(_authService, widget.serverConfig, _liveService);
  late final _profileService = ProfileService(widget.api);
  late final _router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authProvider,
    redirect: (context, state) {
      if (_authProvider.loading) return null;
      final loggedIn = _authProvider.isAuthenticated;
      final path = state.matchedLocation;
      if (!loggedIn) {
        if (path == '/login' || path == '/register') return null;
        return '/login';
      }
      if (path == '/login' || path == '/register' || path == '/') {
        final role = _authProvider.user?.role;
        if (role == UserRole.driver) return '/driver';
        if (role == UserRole.officer) return '/officer';
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/driver', builder: (_, __) => const DriverHomeScreen()),
      GoRoute(path: '/officer', builder: (_, __) => const OfficerHomeScreen()),
    ],
  );

  @override
  void initState() {
    super.initState();
    widget.api.onUnauthorized = () {
      _authProvider.logout();
    };
    _authProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: widget.api),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(
          create: (_) => EmergencyProvider(
            EmergencyService(widget.api),
            _gpsService,
            AiService(widget.api),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DriverLocationProvider(_gpsService),
        ),
        ChangeNotifierProvider(
          create: (_) => LiveAmbulanceProvider(widget.api),
        ),
        ChangeNotifierProvider(
          create: (_) => JunctionProvider(JunctionService(widget.api)),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final notifProvider =
                NotificationProvider(NotificationApiService(widget.api));
            _liveService.onNotification = notifProvider.refresh;
            return notifProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final chatProvider = ChatProvider(ChatApiService(widget.api));
            _liveService.onChatMessage = chatProvider.refresh;
            return chatProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(_profileService),
        ),
      ],
      child: MaterialApp.router(
        title: 'Ambulance Coordination',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kAuthBg,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
