import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/junction_provider.dart';
import '../providers/live_ambulance_provider.dart';
import '../providers/notification_provider.dart';
import 'officer_map_screen.dart';
import 'officer_history_screen.dart';
import 'profile_screen.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NotificationProvider>().setMode(driver: false);
      context.read<LiveAmbulanceProvider>().startPolling();
      context.read<JunctionProvider>().loadClearanceHistory();
    });
  }

  @override
  void dispose() {
    context.read<LiveAmbulanceProvider>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifs = context.watch<NotificationProvider>();
    final live = context.watch<LiveAmbulanceProvider>();
    final junctions = context.watch<JunctionProvider>();

    final pages = <Widget>[
      _buildHomePage(context, live, notifs, junctions),
      const OfficerMapScreen(),
      _buildAlertsPage(context, notifs),
      const OfficerHistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Officer'),
        actions: [
          if (notifs.unreadCount > 0)
            Badge(
              label: Text('${notifs.unreadCount}'),
              child: IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.logout),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomePage(
    BuildContext context,
    LiveAmbulanceProvider live,
    NotificationProvider notifs,
    JunctionProvider junctions,
  ) {
    final activeAmbulances = live.ambulances.length;
    final activeEmergencies = live.ambulances.where((a) => a.status == 'emergency').length;
    final clearedToday = junctions.clearanceHistory.length;

    return RefreshIndicator(
      onRefresh: () async {
        await live.refresh();
        await notifs.load();
        await junctions.loadClearanceHistory();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.local_shipping,
                          label: 'Active\nAmbulances',
                          value: '$activeAmbulances',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statCard(
                          icon: Icons.emergency,
                          label: 'Active\nEmergencies',
                          value: '$activeEmergencies',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.traffic,
                          label: 'Junctions\nCleared',
                          value: '$clearedToday',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statCard(
                          icon: Icons.notifications_active,
                          label: 'Pending\nAlerts',
                          value: '${notifs.unreadCount}',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (notifs.unreadCount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Alerts', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  child: const Text('View All'),
                ),
              ],
            ),
            ...notifs.notifications.take(3).map(
              (n) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                color: n.isAcknowledged ? null : Colors.red.shade50,
                child: ListTile(
                  leading: Icon(Icons.emergency, color: n.isAcknowledged ? Colors.grey : Colors.red),
                  title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: n.isAcknowledged
                      ? const Icon(Icons.check, color: Colors.green, size: 20)
                      : TextButton(
                          onPressed: () => notifs.acknowledge(n.id),
                          child: const Text('ACK'),
                        ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.map, size: 32, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          const Text('View Map', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _showSendMessageDialog(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.message, size: 32, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          const Text('Message\nDriver', style: TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (live.ambulances.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Active Ambulances', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...live.ambulances.map(
              (a) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: const Icon(Icons.local_shipping, color: Colors.red),
                  title: Text(a.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('To: ${a.destination}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${a.etaMinutes?.toStringAsFixed(0) ?? "?"} min',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text(
                        '${a.speedKmh?.toStringAsFixed(0) ?? "?"} km/h',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertsPage(BuildContext context, NotificationProvider notifs) {
    return notifs.loading
        ? const Center(child: CircularProgressIndicator())
        : notifs.notifications.isEmpty
            ? const Center(child: Text('No alerts'))
            : RefreshIndicator(
                onRefresh: notifs.load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifs.notifications.length,
                  itemBuilder: (_, i) {
                    final n = notifs.notifications[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: n.isAcknowledged ? null : Colors.red.shade50,
                      child: ListTile(
                        leading: Icon(Icons.emergency, color: n.isAcknowledged ? Colors.grey : Colors.red),
                        title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(n.message),
                        trailing: n.isAcknowledged
                            ? const Icon(Icons.check, color: Colors.green)
                            : TextButton(onPressed: () => notifs.acknowledge(n.id), child: const Text('ACK')),
                      ),
                    );
                  },
                ),
              );
  }

  void _showSendMessageDialog(BuildContext context) {
    final live = context.read<LiveAmbulanceProvider>();
    if (live.ambulances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active ambulances to message')),
      );
      return;
    }

    int? selectedSessionId;
    final messageCtrl = TextEditingController();
    final titleCtrl = TextEditingController(text: 'Traffic Update');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Message Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedSessionId,
                decoration: const InputDecoration(
                  labelText: 'Select Ambulance',
                  border: OutlineInputBorder(),
                ),
                items: live.ambulances
                    .map((a) => DropdownMenuItem(
                          value: a.emergencySessionId,
                          child: Text('${a.vehicleNumber} — ${a.destination}'),
                        ))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedSessionId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedSessionId == null || messageCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _sendDriverMessage(
                        context,
                        selectedSessionId!,
                        titleCtrl.text.trim(),
                        messageCtrl.text.trim(),
                      );
                    },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDriverMessage(BuildContext context, int sessionId, String title, String message) async {
    try {
      final notifProvider = context.read<NotificationProvider>();
      await notifProvider.sendToDriver(
        emergencySessionId: sessionId,
        title: title,
        message: message,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent to driver')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Widget _statCard({required IconData icon, required String label, required String value, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
