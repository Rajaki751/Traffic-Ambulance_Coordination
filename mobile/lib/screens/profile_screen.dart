import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final user = auth.user;
    final profile = profileProvider.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profileProvider.loading && profile == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (profile?.name ?? user?.name ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Name', profile?.name ?? user?.name ?? '—'),
                    _buildInfoRow('Email', profile?.email ?? user?.email ?? '—'),
                    _buildInfoRow('Role', (profile?.role ?? user?.role.name ?? '—').toUpperCase()),
                    if (profile?.vehicleNumber != null)
                      _buildInfoRow('Vehicle', profile!.vehicleNumber!),
                    if (profile?.assignedZone != null)
                      _buildInfoRow('Zone', profile!.assignedZone!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Name'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditNameDialog(context, profile?.name ?? user?.name ?? ''),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChangePasswordDialog(context),
              ),
            ),

            const SizedBox(height: 8),
            const Text('Map Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Card(
              child: Consumer<SettingsProvider>(builder: (_, s, __) {
                return SwitchListTile(
                  title: const Text('Show traffic overlay'),
                  value: s.showTrafficOverlay,
                  onChanged: (v) => s.setShowTrafficOverlay(v),
                );
              }),
            ),

            const SizedBox(height: 8),
            const Text('Support', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Card(
              child: ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showHelpDialog(context),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(context),
              ),
            ),

            const SizedBox(height: 16),
            if (profileProvider.success != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(profileProvider.success!, style: const TextStyle(color: Colors.green)),
              ),
            if (profileProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(profileProvider.error!, style: const TextStyle(color: Colors.red)),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => auth.logout(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.length >= 2) {
                Navigator.pop(ctx);
                await context.read<ProfileProvider>().updateName(name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v == null || v.length < 8 ? 'Min 8 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v != newCtrl.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                await context.read<ProfileProvider>().changePassword(
                      currentPassword: currentCtrl.text,
                      newPassword: newCtrl.text,
                    );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ambulance Coordination System', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('For emergency support, contact:'),
            SizedBox(height: 8),
            Text('  Dispatch Center: 102'),
            Text('  Technical Support: support@ambulance.gov.np'),
            SizedBox(height: 12),
            Text('User Guide:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('• Use the Map tab to view live ambulance positions'),
            Text('• Accept emergency alerts from the Alerts tab'),
            Text('• Mark junctions as cleared from the Map tab'),
            Text('• Update your profile from this screen'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI-Driven Traffic Ambulance Coordination System', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('A final year project implementing real-time ambulance coordination with AI-powered route optimization for Kathmandu Valley.'),
            SizedBox(height: 12),
            Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('• AI incident prediction'),
            Text('• Real-time GPS tracking'),
            Text('• Route optimization with OSRM'),
            Text('• Traffic officer coordination'),
            Text('• Junction clearance management'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
