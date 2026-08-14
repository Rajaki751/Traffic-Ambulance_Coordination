import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/emergency_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/auth_widgets.dart';

const _kGreen = Color(0xFF2F9E63);
const _kOrange = Color(0xFFE8833A);

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
      if (!mounted) return;
      await context.read<EmergencyProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifs = context.watch<NotificationProvider>();
    final emergency = context.watch<EmergencyProvider>();
    final text = GoogleFonts.inter();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kAuthBg,
        appBar: AppBar(
          backgroundColor: kAuthCard,
          foregroundColor: kAuthText,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const Border(bottom: BorderSide(color: kAuthBorder)),
          title: Text(
            'Alerts',
            style: text.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: kAuthText,
            ),
          ),
          bottom: TabBar(
            indicatorColor: kAuthRed,
            dividerColor: kAuthBorder,
            labelColor: kAuthRedLink,
            unselectedLabelColor: kAuthFaint,
            labelStyle: text.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: text.copyWith(fontSize: 13),
            tabs: const [
              Tab(text: 'Notifications'),
              Tab(text: 'Trip history'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: notifs.load,
              child: notifs.notifications.isEmpty
                  ? const AuthEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications yet',
                      hint:
                          'Emergency alerts and coordination updates from '
                          'dispatch will appear here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifs.notifications.length,
                      itemBuilder: (_, i) {
                        final n = notifs.notifications[i];
                        return Card(
                          margin:
                              const EdgeInsets.symmetric(vertical: 6),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          color: kAuthCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: kAuthBorder),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            leading: Icon(
                              n.isRead
                                  ? Icons.notifications_off
                                  : Icons.notifications,
                              color: n.isRead ? kAuthIcon : _kOrange,
                            ),
                            title: Text(
                              n.title,
                              style: text.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: kAuthText,
                              ),
                            ),
                            subtitle: Text(
                              n.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.copyWith(
                                fontSize: 13,
                                color: kAuthMuted,
                              ),
                            ),
                            trailing: n.isRead
                                ? Icon(
                                    Icons.done,
                                    color: _kGreen,
                                    size: 20,
                                  )
                                : TextButton(
                                    onPressed: () => notifs.markRead(n.id),
                                    style: TextButton.styleFrom(
                                      foregroundColor: kAuthRedLink,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Read',
                                      style: text.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            RefreshIndicator(
              onRefresh: emergency.loadHistory,
              child: emergency.history.isEmpty
                  ? const AuthEmptyState(
                      icon: Icons.history_rounded,
                      title: 'No trip history yet',
                      hint:
                          'Completed emergency trips will show up here with '
                          'status and date.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: emergency.history.length,
                      itemBuilder: (_, i) {
                        final h = emergency.history[i];
                        return Card(
                          margin:
                              const EdgeInsets.symmetric(vertical: 6),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          color: kAuthCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: kAuthBorder),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            leading: Icon(
                              h.endedAt != null
                                  ? Icons.check_circle
                                  : Icons.access_time,
                              color:
                                  h.endedAt != null ? _kGreen : _kOrange,
                            ),
                            title: Text(
                              h.destination,
                              style: text.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: kAuthText,
                              ),
                            ),
                            subtitle: Text(
                              '${h.status} • ${h.incidentType ?? "general"}',
                              style: text.copyWith(
                                fontSize: 13,
                                color: kAuthMuted,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  h.endedAt != null ? 'Done' : 'Open',
                                  style: text.copyWith(
                                    color: h.endedAt != null
                                        ? _kGreen
                                        : _kOrange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                if (h.endedAt != null)
                                  Text(
                                    h.endedAt!.toIso8601String().substring(
                                        0, 10),
                                    style: text.copyWith(
                                      fontSize: 10,
                                      color: kAuthFaint,
                                    ),
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