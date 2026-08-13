import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/emergency_provider.dart';
import '../providers/notification_provider.dart';

class DriverUpdatesScreen extends StatefulWidget {
  const DriverUpdatesScreen({super.key});

  @override
  State<DriverUpdatesScreen> createState() => _DriverUpdatesScreenState();
}

class _DriverUpdatesScreenState extends State<DriverUpdatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NotificationProvider>().setMode(driver: true);
      await context.read<EmergencyProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifs = context.watch<NotificationProvider>();
    final emergency = context.watch<EmergencyProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Driver Updates'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Notifications'),
              Tab(text: 'Trip History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: notifs.load,
              child: notifs.notifications.isEmpty
                  ? const Center(child: Text('No notifications yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notifs.notifications.length,
                      itemBuilder: (_, i) {
                        final n = notifs.notifications[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              n.isRead ? Icons.notifications_off : Icons.notifications,
                              color: n.isRead ? Colors.grey : Colors.orange,
                            ),
                            title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: n.isRead
                                ? const Icon(Icons.done, color: Colors.green, size: 20)
                                : TextButton(
                                    onPressed: () => notifs.markRead(n.id),
                                    child: const Text('Read'),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            RefreshIndicator(
              onRefresh: emergency.loadHistory,
              child: emergency.history.isEmpty
                  ? const Center(child: Text('No trip history yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: emergency.history.length,
                      itemBuilder: (_, i) {
                        final h = emergency.history[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              h.endedAt != null ? Icons.check_circle : Icons.access_time,
                              color: h.endedAt != null ? Colors.green : Colors.orange,
                            ),
                            title: Text(h.destination, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${h.status} • ${h.incidentType ?? "general"}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  h.endedAt != null ? 'Done' : 'Open',
                                  style: TextStyle(
                                    color: h.endedAt != null ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                if (h.endedAt != null)
                                  Text(
                                    h.endedAt!.toIso8601String().substring(0, 10),
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
