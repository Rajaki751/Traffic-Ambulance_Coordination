import 'package:flutter/material.dart';
import '../core/theme.dart';

class EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool loading;
  final String label;

  const EmergencyButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'ACTIVATE EMERGENCY',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.emergencyRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: AppTheme.emergencyRed.withOpacity(0.5),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
