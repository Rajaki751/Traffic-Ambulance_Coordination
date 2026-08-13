import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

const kAuthEmberLight = Color(0xFFF04438);
const kAuthEmber = AppTheme.emergencyRed;
const kAuthEmberDark = Color(0xFF8F1412);
const kAuthBase = Color(0xFF0A0A0C);

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.35,
                colors: [
                  kAuthEmber.withOpacity(0.10),
                  kAuthEmber.withOpacity(0.045),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        const Positioned(
          top: -240,
          left: -180,
          child: _Glow(color: kAuthEmber, size: 520, opacity: 0.09),
        ),
        child,
      ],
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

class AuthEmblem extends StatelessWidget {
  const AuthEmblem({super.key, this.icon = Icons.medical_services_outlined});

  final IconData icon;

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
            color: kAuthEmber.withOpacity(0.14),
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
                  kAuthEmberLight.withOpacity(0.50),
                  kAuthEmber.withOpacity(0.20),
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
              colors: [kAuthEmberLight, kAuthEmber, kAuthEmberDark],
            ).createShader(rect),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.onToggleObscure,
    this.helper,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? helper;
  final String? Function(String?) validator;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused
                  ? kAuthEmber.withOpacity(0.85)
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
                      color: kAuthEmber.withOpacity(0.30),
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
            cursorColor: kAuthEmberLight,
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
                    ? kAuthEmberLight
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
                color: const Color(0xFFFF9B8F),
              ),
              errorMaxLines: 2,
            ),
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.helper!,
              style: text.copyWith(
                fontSize: 11.5,
                color: Colors.white.withOpacity(0.38),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AuthDropdownField extends StatefulWidget {
  const AuthDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  State<AuthDropdownField> createState() => _AuthDropdownFieldState();
}

class _AuthDropdownFieldState extends State<AuthDropdownField> {
  final _focus = FocusNode();
  bool _open = false;

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
    final focused = _focus.hasFocus || _open;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused
              ? kAuthEmber.withOpacity(0.85)
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
                  color: kAuthEmber.withOpacity(0.30),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          focusNode: _focus,
          value: widget.value,
          isExpanded: true,
          onChanged: (v) {
            setState(() => _open = false);
            widget.onChanged(v);
          },
          dropdownColor: const Color(0xFF141419),
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          style: text.copyWith(fontSize: 15, color: Colors.white),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Colors.white.withOpacity(0.50),
          ),
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
              color: focused ? kAuthEmberLight : Colors.white.withOpacity(0.60),
            ),
            prefixIcon: Icon(
              widget.icon,
              size: 20,
              color: Colors.white.withOpacity(0.50),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 17),
          ),
          items: widget.items,
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final text = GoogleFonts.inter();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kAuthEmber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kAuthEmber.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: kAuthEmberLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: text.copyWith(
                fontSize: 12.5,
                color: const Color(0xFFFFB4A8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthGlowButton extends StatefulWidget {
  const AuthGlowButton({
    super.key,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final VoidCallback onPressed;

  @override
  State<AuthGlowButton> createState() => _AuthGlowButtonState();
}

class _AuthGlowButtonState extends State<AuthGlowButton> {
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
                colors: [kAuthEmberLight, kAuthEmber, kAuthEmberDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: kAuthEmber.withOpacity(_pressed ? 0.30 : 0.45),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: kAuthEmber.withOpacity(_pressed ? 0.12 : 0.22),
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

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = GoogleFonts.inter();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: text.copyWith(
            fontSize: 13.5,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          child: Text(
            action,
            style: text.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
