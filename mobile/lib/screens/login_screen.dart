import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';
import 'register_screen.dart';

import '../services/server_config_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _serverConfig = ServerConfigService();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showServerDialog() async {
    final currentUrl = await _serverConfig.getApiBaseUrl();
    if (!mounted) return;
    final ctrl = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Server Configuration',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backend API URL:',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[300]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: 'https://...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            Text('Presets:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Live Cloud (Render)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'https://sajiloroute-api.onrender.com',
                ),
                ActionChip(
                  label: const Text('Localhost (PC)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://localhost:8000',
                ),
                ActionChip(
                  label: const Text('Android VM (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://10.0.2.2:8000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final url = ctrl.text.trim();
              if (url.isNotEmpty && mounted) {
                final auth = context.read<AuthProvider>();
                await auth.configureServer(url);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save & Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final text = GoogleFonts.inter();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackdrop(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AuthBadge(),
                          IconButton(
                            icon: const Icon(Icons.dns_outlined, size: 20, color: kAuthMuted),
                            tooltip: 'Server Settings',
                            visualDensity: VisualDensity.compact,
                            onPressed: _showServerDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Center(child: AuthEmblem()),
                      const SizedBox(height: 24),
                      Text(
                        'Ambulance coordination',
                        textAlign: TextAlign.center,
                        style: text.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.24,
                          color: kAuthText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Driver & Traffic Officer Portal',
                        textAlign: TextAlign.center,
                        style: text.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: kAuthMuted,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AuthCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthField(
                              controller: _emailCtrl,
                              label: 'Email',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Email required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AuthField(
                              controller: _passCtrl,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePass,
                              onToggleObscure: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                              validator: (v) => v == null || v.length < 6
                                  ? 'Password required'
                                  : null,
                            ),
                            if (auth.error != null) ...[
                              const SizedBox(height: 16),
                              AuthErrorBanner(message: auth.error!),
                            ],
                            const SizedBox(height: 24),
                            AuthPrimaryButton(
                              loading: auth.loading,
                              label: 'Sign In',
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                await auth.login(
                                  _emailCtrl.text.trim(),
                                  _passCtrl.text,
                                );
                              },
                            ),
                          ],
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
