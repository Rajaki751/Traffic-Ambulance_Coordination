import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
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
import 'services/emergency_service.dart';
import 'services/gps_service.dart';
import 'services/junction_service.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'services/server_config_service.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  final serverConfig = ServerConfigService();
  api.setBaseUrl(await serverConfig.getApiBaseUrl());
  runApp(AmbulanceApp(api: api, serverConfig: serverConfig));
}

class AmbulanceApp extends StatefulWidget {
  const AmbulanceApp({super.key, required this.api, required this.serverConfig});

  final ApiService api;
  final ServerConfigService serverConfig;

  @override
  State<AmbulanceApp> createState() => _AmbulanceAppState();
}

class _AmbulanceAppState extends State<AmbulanceApp> {
  late final GpsTrackingService _gpsService = GpsTrackingService(widget.api);
  late final _authService = AuthService(widget.api);
  late final _authProvider = AuthProvider(_authService, widget.serverConfig);
  late final _profileService = ProfileService(widget.api);
  late final _router = GoRouter(
    refreshListenable: _authProvider,
    redirect: (context, state) {
      final loggedIn = _authProvider.isAuthenticated;
      final onLogin = state.matchedLocation == '/login';
      final onRegister = state.matchedLocation == '/register';
      if (!loggedIn && !onLogin && !onRegister) return '/login';
      if (loggedIn && (onLogin || onRegister)) {
        final role = _authProvider.user?.role;
        if (role == UserRole.driver) return '/driver';
        if (role == UserRole.officer) return '/officer';
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/driver', builder: (_, __) => const DriverHomeScreen()),
      GoRoute(path: '/officer', builder: (_, __) => const OfficerHomeScreen()),
    ],
  );

  @override
  void initState() {
    super.initState();
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
          create: (_) => NotificationProvider(NotificationApiService(widget.api)),
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
        themeMode: ThemeMode.system,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
