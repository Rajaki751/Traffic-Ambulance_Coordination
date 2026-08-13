import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/server_config_service.dart';
import 'register_screen.dart';

const _kEmberLight = Color(0xFFF04438);
const _kEmber = AppTheme.emergencyRed;
const _kEmberDark = Color(0xFF8F1412);
const _kBase = Color(0xFF0A0A0C);

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
  bool _demoOpen = false;

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
      backgroundColor: _kBase,
      body: Stack(
        children: [
          const Positioned(
            top: -180,
            left: -140,
            child: _Glow(color: _kEmber, size: 460, opacity: 0.14),
          ),
          const Positioned(
            bottom: -220,
            right: -160,
            child: _Glow(color: _kEmber, size: 420, opacity: 0.07),
          ),
          SafeArea(
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
                        const _Badge(),
                        const SizedBox(height: 24),
                        const Center(child: _Emblem()),
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
                                            _PxField(
                                              controller: _serverCtrl,
                                              label: 'Server URL',
                                              icon: Icons.dns_outlined,
                                              keyboardType:
                                                  TextInputType.url,
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
                                    _PxField(
                                      controller: _emailCtrl,
                                      label: 'Email',
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Email required'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _PxField(
                                      controller: _passCtrl,
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      obscure: _obscurePass,
                                      onToggleObscure: () => setState(
                                          () => _obscurePass =
                                              !_obscurePass),
                                      validator: (v) => v == null ||
                                              v.length < 6
                                          ? 'Password required'
                                          : null,
                                    ),
                                    if (auth.error != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _kEmber.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _kEmber.withOpacity(0.30),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              size: 17,
                                              color: _kEmberLight,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                auth.error!,
                                                style: text.copyWith(
                                                  fontSize: 12.5,
                                                  color:
                                                      Color(0xFFFFB4A8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    _GlowButton(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: text.copyWith(
                                fontSize: 13.5,
                                color: Colors.white.withOpacity(0.55),
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
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                'Register',
                                style: text.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _DisclosureBlock(
                          title: 'View demo access',
                          open: _demoOpen,
                          onToggle: () =>
                              setState(() => _demoOpen = !_demoOpen),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'Driver: driver@ambulance.gov / Driver@12345\n'
                              'Officer: officer@ambulance.gov / Officer@12345',
                              textAlign: TextAlign.center,
                              style: text.copyWith(
                                fontSize: 11.5,
                                height: 1.6,
                                color: Colors.white.withOpacity(0.45),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulseDot(),
            const SizedBox(width: 8),
            Text(
              'EMERGENCY RESPONSE NETWORK',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.88,
                color: Colors.white.withOpacity(0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kEmberLight,
            boxShadow: [
              BoxShadow(
                color: _kEmber.withOpacity(0.35 + 0.45 * t),
                blurRadius: 2 + 6 * t,
                spreadRadius: 0.5 + 1.5 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17171B), Color(0xFF0E0E12)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _kEmber.withOpacity(0.14),
            blurRadius: 60,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _kEmberLight.withOpacity(0.50),
                  _kEmber.withOpacity(0.20),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kEmberLight, _kEmber, _kEmberDark],
            ).createShader(rect),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PxField extends StatefulWidget {
  const _PxField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.onToggleObscure,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?) validator;

  @override
  State<_PxField> createState() => _PxFieldState();
}

class _PxFieldState extends State<_PxField> {
  final _focus = FocusNode();
  bool _eyeHover = false;
  bool _eyePressed = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = GoogleFonts.inter();
    final focused = _focus.hasFocus;
    return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused
                  ? _kEmber.withOpacity(0.85)
                  : Colors.white.withOpacity(0.09),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(focused ? 0.07 : 0.055),
                Colors.white.withOpacity(focused ? 0.035 : 0.025),
              ],
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: _kEmber.withOpacity(0.30),
                      blurRadius: 22,
                      spreadRadius: -2,
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: text.copyWith(fontSize: 15, color: Colors.white),
            cursorColor: _kEmberLight,
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: text.copyWith(
                fontSize: 14,
                color: focused
                    ? Colors.white.withOpacity(0.85)
                    : Colors.white.withOpacity(0.45),
              ),
              floatingLabelStyle: text.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: focused
                    ? _kEmberLight
                    : Colors.white.withOpacity(0.60),
              ),
              prefixIcon: Icon(
                widget.icon,
                size: 20,
                color: Colors.white.withOpacity(0.50),
              ),
              suffixIcon: widget.onToggleObscure != null
                  ? MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _eyeHover = true),
                      onExit: (_) => setState(() => _eyeHover = false),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => setState(() => _eyePressed = true),
                        onTapUp: (_) {
                          setState(() => _eyePressed = false);
                          widget.onToggleObscure!();
                        },
                        onTapCancel: () => setState(() => _eyePressed = false),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            widget.obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: Colors.white.withOpacity(
                                _eyeHover || _eyePressed ? 1.0 : 0.55),
                          ),
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 17),
              errorStyle: text.copyWith(
                fontSize: 12,
                color: Color(0xFFFF9B8F),
              ),
              errorMaxLines: 2,
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

class _DisclosureBlock extends StatelessWidget {
  const _DisclosureBlock({
    required this.title,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DisclosureRow(title: title, open: open, onToggle: onToggle),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: child,
          crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 240),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

class _GlowButton extends StatefulWidget {
  const _GlowButton({
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final text = GoogleFonts.inter();
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kEmberLight, _kEmber, _kEmberDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: _kEmber.withOpacity(_pressed ? 0.30 : 0.45),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: _kEmber.withOpacity(_pressed ? 0.12 : 0.22),
                  blurRadius: 48,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _hover && !_pressed ? 0.06 : 0,
                  child: Container(color: Colors.white),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _pressed ? 0.14 : 0,
                  child: Container(color: Colors.black),
                ),
                ElevatedButton(
                  onPressed: widget.loading ? null : widget.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: widget.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.label,
                              style: text.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                              color: Color(0xFFFFFFFF),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}