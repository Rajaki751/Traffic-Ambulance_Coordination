import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/server_config_service.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.person_add, size: 64, color: AppTheme.emergencyRed),
                const SizedBox(height: 16),
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register as Driver or Traffic Officer',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Name required (min 2 chars)' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || v.isEmpty || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    helperText: 'Min 8 characters',
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 8 ? 'Password must be at least 8 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v != _passCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'driver', child: Text('Driver')),
                    DropdownMenuItem(value: 'officer', child: Text('Traffic Officer')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'driver'),
                ),
                if (_role == 'driver') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number',
                      prefixIcon: Icon(Icons.local_shipping),
                      border: OutlineInputBorder(),
                      helperText: 'e.g. BA 1 KHA 1234',
                    ),
                    validator: (v) => _role == 'driver' && (v == null || v.trim().isEmpty)
                        ? 'Vehicle number required for drivers'
                        : null,
                  ),
                ],
                if (_role == 'officer') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _zoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Zone',
                      prefixIcon: Icon(Icons.map),
                      border: OutlineInputBorder(),
                      helperText: 'e.g. New Baneshwor',
                    ),
                    validator: (v) => _role == 'officer' && (v == null || v.trim().isEmpty)
                        ? 'Assigned zone required for officers'
                        : null,
                  ),
                ],
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Text(auth.error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
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
                          if (auth.isAuthenticated && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: auth.loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
