import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/server_config_service.dart';
import '../widgets/auth_widgets.dart';
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
  bool _advancedOpen = false;

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
    final text = GoogleFonts.inter();

    return Scaffold(
      backgroundColor: kAuthBase,
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Center(child: AuthEmblem()),
                      const SizedBox(height: 24),
                      Text(
                        'Ambulance Coordination',
                        textAlign: TextAlign.center,
                        style: text.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Driver & Traffic Officer Portal',
                        textAlign: TextAlign.center,
                        style: text.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.57),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 60,
                              offset: Offset(0, 28),
                            ),
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withOpacity(0.045),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _DisclosureRow(
                                    title: 'Advanced settings',
                                    open: _advancedOpen,
                                    onToggle: () => setState(
                                        () => _advancedOpen = !_advancedOpen),
                                  ),
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox(
                                        width: double.infinity),
                                    secondChild: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 16, bottom: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AuthField(
                                            controller: _serverCtrl,
                                            label: 'Server URL',
                                            icon: Icons.dns_outlined,
                                            keyboardType: TextInputType.url,
                                            validator: (v) {
                                              if (v == null ||
                                                  v.trim().isEmpty) {
                                                return 'Server URL required';
                                              }
                                              if (!v.contains(':')) {
                                                return 'Include port, e.g. '
                                                    'http://192.168.x.x:8000';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Use your PC IP on a physical '
                                            'phone (same Wi-Fi)',
                                            style: text.copyWith(
                                              fontSize: 11.5,
                                              color: Colors.white
                                                  .withOpacity(0.38),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    crossFadeState: _advancedOpen
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration:
                                        const Duration(milliseconds: 260),
                                    sizeCurve: Curves.easeOutCubic,
                                  ),
                                  const SizedBox(height: 18),
                                  AuthField(
                                    controller: _emailCtrl,
                                    label: 'Email',
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Email required'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  AuthField(
                                    controller: _passCtrl,
                                    label: 'Password',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscurePass,
                                    onToggleObscure: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                    validator: (v) => v == null ||
                                            v.length < 6
                                        ? 'Password required'
                                        : null,
                                  ),
                                  if (auth.error != null) ...[
                                    const SizedBox(height: 16),
                                    AuthErrorBanner(message: auth.error!),
                                  ],
                                  const SizedBox(height: 24),
                                  AuthGlowButton(
                                    loading: auth.loading,
                                    label: 'Sign In',
                                    onPressed: () async {
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
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthFooterLink(
                        question: "Don't have an account? ",
                        action: 'Register',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclosureRow extends StatelessWidget {
  const _DisclosureRow({
    required this.title,
    required this.open,
    required this.onToggle,
  });

  final String title;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = GoogleFonts.inter();
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: text.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.42),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}