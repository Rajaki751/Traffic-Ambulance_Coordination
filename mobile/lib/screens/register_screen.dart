import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/server_config_service.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _serverConfig = ServerConfigService();
  String _role = 'driver';
  String? _serverUrl;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final url = await _serverConfig.getApiBaseUrl();
    if (!mounted) return;
    setState(() {
      _serverUrl = url.contains('10.0.2.2') ? '' : url;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_serverUrl != null && _serverUrl!.isNotEmpty) {
      await auth.configureServer(_serverUrl!);
    }
    await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
      vehicleNumber: _role == 'driver' ? _vehicleCtrl.text.trim() : null,
      assignedZone: _role == 'officer' ? _zoneCtrl.text.trim() : null,
    );
    if (auth.isAuthenticated && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _vehicleCtrl.dispose();
    _zoneCtrl.dispose();
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
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              hoverColor: Colors.white.withOpacity(0.06),
                              foregroundColor: Colors.white,
                            ),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                              color: Colors.white.withOpacity(0.60),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Register',
                            style: text.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: AuthEmblem(icon: Icons.person_add_alt_1_rounded),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Account',
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
                        'Register as Driver or Traffic Officer',
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
                                  AuthField(
                                    controller: _nameCtrl,
                                    label: 'Full Name',
                                    icon: Icons.person_outline_rounded,
                                    validator: (v) => v == null ||
                                            v.trim().length < 2
                                        ? 'Name required (min 2 chars)'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  AuthField(
                                    controller: _emailCtrl,
                                    label: 'Email',
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) => v == null ||
                                            v.isEmpty ||
                                            !v.contains('@')
                                        ? 'Valid email required'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  AuthField(
                                    controller: _passCtrl,
                                    label: 'Password',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscurePass,
                                    onToggleObscure: () => setState(() =>
                                        _obscurePass = !_obscurePass),
                                    helper: 'Min 8 characters',
                                    validator: (v) => v == null ||
                                            v.length < 8
                                        ? 'Password must be at least 8 '
                                            'characters'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  AuthField(
                                    controller: _confirmCtrl,
                                    label: 'Confirm Password',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscureConfirm,
                                    onToggleObscure: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                    validator: (v) =>
                                        v != _passCtrl.text
                                            ? 'Passwords do not match'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  AuthDropdownField(
                                    label: 'Role',
                                    icon: Icons.badge_outlined,
                                    value: _role,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'driver',
                                        child: Text('Driver'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'officer',
                                        child: Text('Traffic Officer'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _role = v ?? 'driver'),
                                  ),
                                  if (_role == 'driver') ...[
                                    const SizedBox(height: 14),
                                    AuthField(
                                      controller: _vehicleCtrl,
                                      label: 'Vehicle Number',
                                      icon: Icons.local_shipping_outlined,
                                      helper: 'e.g. BA 1 KHA 1234',
                                      validator: (v) => v == null ||
                                              v.trim().isEmpty
                                          ? 'Vehicle number required for '
                                              'drivers'
                                          : null,
                                    ),
                                  ],
                                  if (_role == 'officer') ...[
                                    const SizedBox(height: 14),
                                    AuthField(
                                      controller: _zoneCtrl,
                                      label: 'Assigned Zone',
                                      icon: Icons.map_outlined,
                                      helper: 'e.g. New Baneshwor',
                                      validator: (v) => v == null ||
                                              v.trim().isEmpty
                                          ? 'Assigned zone required for '
                                              'officers'
                                          : null,
                                    ),
                                  ],
                                  if (auth.error != null) ...[
                                    const SizedBox(height: 16),
                                    AuthErrorBanner(message: auth.error!),
                                  ],
                                  const SizedBox(height: 24),
                                  AuthGlowButton(
                                    loading: auth.loading,
                                    label: 'Register',
                                    onPressed: _submit,
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
                        question: 'Already have an account? ',
                        action: 'Sign In',
                        onTap: () => Navigator.pop(context),
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