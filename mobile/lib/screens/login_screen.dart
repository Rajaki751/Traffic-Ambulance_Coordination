import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/server_config_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(text: 'driver@ambulance.gov');
  final _passCtrl = TextEditingController(text: 'Driver@12345');
  final _formKey = GlobalKey<FormState>();
  final _serverConfig = ServerConfigService();
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final url = await _serverConfig.getApiBaseUrl();
    if (!mounted) return;
    setState(() {
      _serverCtrl.text = url;
    });
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF2A0A10),
                    Color(0xFF3D0F18),
                    Color(0xFF121212),
                  ]
                : const [
                    Color(0xFFFFF1F0),
                    Color(0xFFFFE4E2),
                    Color(0xFFFDF6F5),
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _glowCircle(230, isDark),
            ),
            Positioned(
              bottom: -110,
              left: -80,
              child: _glowCircle(270, isDark),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : AppTheme.emergencyRed.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.15)
                                      : AppTheme.emergencyRed.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: AppTheme.emergencyRed,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.emergencyRed
                                              .withOpacity(0.8),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'EMERGENCY RESPONSE NETWORK',
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1.6,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white70
                                          : AppTheme.emergencyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF5A50),
                                    AppTheme.emergencyRed,
                                    AppTheme.emergencyDark,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.emergencyRed
                                        .withOpacity(0.45),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.medical_services_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Ambulance Coordination',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2A0A10),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Driver & Traffic Officer Portal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.07)
                                  : Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.black.withOpacity(0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                      isDark ? 0.45 : 0.10),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildField(
                                  controller: _serverCtrl,
                                  label: 'Server URL',
                                  icon: Icons.dns_outlined,
                                  hint: 'http://192.168.18.88:8000',
                                  helper:
                                      'Use your PC IP on a physical phone (same Wi-Fi)',
                                  keyboardType: TextInputType.url,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Server URL required';
                                    }
                                    if (!v.contains(':')) {
                                      return 'Include port, e.g. http://192.168.x.x:8000';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Email required'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePass,
                                  style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  decoration: _fieldDecoration(
                                    label: 'Password',
                                    icon: Icons.lock_outline_rounded,
                                    isDark: isDark,
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                          () => _obscurePass = !_obscurePass),
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                  ),
                                  validator: (v) => v == null || v.length < 6
                                      ? 'Password required'
                                      : null,
                                ),
                                if (auth.error != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emergencyRed
                                          .withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.emergencyRed
                                            .withOpacity(0.35),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppTheme.emergencyRed,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            auth.error!,
                                            style: const TextStyle(
                                              color: AppTheme.emergencyRed,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                SizedBox(
                                  height: 54,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5A50),
                                          AppTheme.emergencyRed,
                                          AppTheme.emergencyDark,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.emergencyRed
                                              .withOpacity(0.40),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: auth.loading
                                          ? null
                                          : () async {
                                              if (!_formKey.currentState!
                                                  .validate()) {
                                                return;
                                              }
                                              await auth.configureServer(
                                                  _serverCtrl.text.trim());
                                              await auth.login(
                                                _emailCtrl.text.trim(),
                                                _passCtrl.text,
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: auth.loading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_forward_rounded,
                                                    size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.emergencyRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Demo · Driver: driver@ambulance.gov / Driver@12345\n'
                              'Officer: officer@ambulance.gov / Officer@12345',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.5,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowCircle(double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            (isDark
                    ? AppTheme.emergencyRed
                    : AppTheme.emergencyRed.withOpacity(0.55))
                .withOpacity(0.20),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      keyboardType: keyboardType,
      validator: validator,
      decoration: _fieldDecoration(
        label: label,
        icon: icon,
        hint: hint,
        helper: helper,
        isDark: isDark,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? helper,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    final base = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.045);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperStyle: TextStyle(fontSize: 11, height: 1.3, color: isDark ? Colors.white38 : Colors.black38),
      prefixIcon: Icon(icon, size: 21, color: isDark ? Colors.white54 : Colors.black45),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: base,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.emergencyRed, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.emergencyRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.emergencyRed, width: 1.6),
      ),
    );
  }
}