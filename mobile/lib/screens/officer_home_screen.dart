import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/junction_provider.dart';
import '../providers/live_ambulance_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/auth_widgets.dart';
import 'officer_map_screen.dart';
import 'officer_history_screen.dart';
import 'profile_screen.dart';

const _kBlue = Color(0xFF2E6FD8);
const _kGreen = Color(0xFF2F9E63);
const _kOrange = Color(0xFFE8833A);
const _kNeutralTint = Color(0xFFF2F1ED);
const _kBlueTint = Color(0xFFEAF1FC);
const _kOrangeTint = Color(0xFFFDF1E7);

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
      if (!mounted) return;
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
    final notifs = context.watch<NotificationProvider>();
    final live = context.watch<LiveAmbulanceProvider>();
    final junctions = context.watch<JunctionProvider>();

    final pages = <Widget>[
      SafeArea(top: true, bottom: false, child: _buildHomePage(context, live, notifs, junctions)),
      const OfficerMapScreen(),
      _buildAlertsPage(context, notifs),
      const OfficerHistoryScreen(),
      const SafeArea(top: true, bottom: false, child: ProfileScreen()),
    ];

    return Scaffold(
      backgroundColor: kAuthBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.012),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kAuthCard,
          border: Border(top: BorderSide(color: kAuthBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _navItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _navItem(
                  index: 1,
                  icon: Icons.map_outlined,
                  selectedIcon: Icons.map_rounded,
                  label: 'Map',
                ),
                _navItem(
                  index: 2,
                  icon: Icons.warning_amber_outlined,
                  selectedIcon: Icons.warning_amber_rounded,
                  label: 'Alerts',
                  badgeCount: notifs.unreadCount,
                ),
                _navItem(
                  index: 3,
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history_rounded,
                  label: 'History',
                ),
                _navItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final active = _selectedIndex == index;
    final text = GoogleFonts.inter();
    final glyph = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          active ? selectedIcon : icon,
          size: 21,
          color: active ? kAuthRedLink : kAuthIcon,
        ),
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: kAuthRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$badgeCount',
                style: text.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        hoverColor: kAuthBorder.withValues(alpha: 0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 28,
              decoration: BoxDecoration(
                color: active ? kAuthRedBadgeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: glyph,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: text.copyWith(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? kAuthRedLink : kAuthIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage(
    BuildContext context,
    LiveAmbulanceProvider live,
    NotificationProvider notifs,
    JunctionProvider junctions,
  ) {
    final text = GoogleFonts.inter();
    final auth = context.watch<AuthProvider>();
    final officerName = auth.user?.name.trim() ?? '';
    final firstName = officerName.isEmpty
        ? 'Officer'
        : officerName.split(' ').first;
    final activeAmbulances = live.ambulances.length;
    final activeEmergencies =
        live.ambulances.where((a) => a.status == 'emergency').length;
    final clearedToday = junctions.clearanceHistory.length;

    return RefreshIndicator(
      onRefresh: () async {
        await live.refresh();
        await notifs.load();
        await junctions.loadClearanceHistory();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispatch desk',
                      style: text.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                        color: kAuthFaint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_greetingPrefix(DateTime.now())}, $firstName',
                      style: text.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: kAuthText,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kAuthRedBadgeBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kAuthRed.withValues(alpha: 0.25)),
                  boxShadow: kCardShadow,
                ),
                child: Center(
                  child: Text(
                    firstName.isEmpty ? 'O' : firstName[0].toUpperCase(),
                    style: text.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kAuthRedLink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kAuthCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kAuthBorder),
              boxShadow: kCardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activeEmergencies > 0
                        ? kAuthRedBadgeBg
                        : _kNeutralTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    activeEmergencies > 0
                        ? Icons.emergency_rounded
                        : Icons.local_shipping_rounded,
                    size: 20,
                    color: activeEmergencies > 0 ? kAuthRed : kAuthMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live operations',
                        style: text.copyWith(
                          fontSize: 12.5,
                          color: kAuthFaint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeEmergencies > 0
                            ? '$activeAmbulances ambulances • '
                                '$activeEmergencies emergency'
                            : 'No active emergencies',
                        style: text.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: activeEmergencies > 0
                              ? kAuthRedBadgeText
                              : kAuthMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                icon: Icons.local_shipping_rounded,
                label: 'Active ambulances',
                value: '$activeAmbulances',
                iconColor: _kBlue,
                tint: _kBlueTint,
              ),
              const SizedBox(width: 12),
              _statCard(
                icon: Icons.emergency_rounded,
                label: 'Emergencies',
                value: '$activeEmergencies',
                iconColor: kAuthRed,
                tint: kAuthRedBadgeBg,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                icon: Icons.traffic_rounded,
                label: 'Junctions cleared',
                value: '$clearedToday',
                iconColor: _kGreen,
                tint: kAuthGreenBg,
              ),
              const SizedBox(width: 12),
              _statCard(
                icon: Icons.notifications_rounded,
                label: 'Pending alerts',
                value: '${notifs.unreadCount}',
                iconColor: notifs.unreadCount > 0 ? _kOrange : kAuthMuted,
                tint: notifs.unreadCount > 0 ? _kOrangeTint : _kNeutralTint,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Quick actions',
                style: text.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kAuthText,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Divider(color: kAuthBorder, height: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  text,
                  icon: Icons.map_rounded,
                  iconColor: _kBlue,
                  tint: _kBlueTint,
                  label: 'Live map',
                  sub: 'Track fleet & clear junctions',
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  text,
                  icon: Icons.message_rounded,
                  iconColor: _kOrange,
                  tint: _kOrangeTint,
                  label: 'Message driver',
                  sub: 'Send a dispatch update',
                  onTap: () => _showSendMessageDialog(context),
                ),
              ),
            ],
          ),
          if (notifs.unreadCount > 0) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Recent alerts',
                  style: text.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kAuthText,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 2),
                  child: Text(
                    'View all',
                    style: text.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kAuthRedLink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...notifs.notifications.take(3).map(
              (n) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                color: n.isAcknowledged
                    ? null
                    : Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.emergency_rounded,
                    color: n.isAcknowledged
                        ? Theme.of(context).colorScheme.outline
                        : kAuthRed,
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
                  trailing: n.isAcknowledged
                      ? const Icon(Icons.check, color: kAuthGreen, size: 20)
                      : TextButton(
                          onPressed: () => notifs.acknowledge(n.id),
                          style: TextButton.styleFrom(
                            foregroundColor: kAuthRedLink,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'ACK',
                            style: text.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
          if (live.ambulances.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Active ambulances',
                  style: text.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kAuthText,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Divider(color: kAuthBorder, height: 1)),
              ],
            ),
            const SizedBox(height: 8),
            ...live.ambulances.map(
              (a) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kAuthRedBadgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      size: 18,
                      color: kAuthRed,
                    ),
                  ),
                  title: Text(
                    a.vehicleNumber,
                    style: text.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: kAuthText,
                    ),
                  ),
                  subtitle: Text(
                    'To: ${a.destination}',
                    style: text.copyWith(fontSize: 13, color: kAuthMuted),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${a.etaMinutes?.toStringAsFixed(0) ?? "?"} min',
                        style: text.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: kAuthRed,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      Text(
                        '${a.speedKmh?.toStringAsFixed(0) ?? "?"} km/h',
                        style: text.copyWith(
                          fontSize: 11,
                          color: kAuthFaint,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
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
    final text = GoogleFonts.inter();
    return Scaffold(
      backgroundColor: kAuthBg,
      appBar: AppBar(
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
      ),
      body: notifs.loading
          ? const Center(child: CircularProgressIndicator())
          : notifs.notifications.isEmpty
              ? const AuthEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No alerts yet',
                  hint:
                      'Emergency alerts appear here as soon as a driver '
                      'starts a trip.',
                )
              : RefreshIndicator(
                  onRefresh: notifs.load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifs.notifications.length,
                    itemBuilder: (_, i) {
                      final n = notifs.notifications[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: n.isAcknowledged
                            ? null
                            : Theme.of(context).colorScheme.errorContainer,
                        child: ListTile(
                          leading: Icon(
                            Icons.emergency_rounded,
                            color: n.isAcknowledged
                                ? Theme.of(context).colorScheme.outline
                                : kAuthRed,
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
                            style: text.copyWith(
                              fontSize: 13,
                              color: kAuthMuted,
                            ),
                          ),
                          trailing: n.isAcknowledged
                              ? const Icon(Icons.check, color: kAuthGreen)
                              : TextButton(
                                  onPressed: () => notifs.acknowledge(n.id),
                                  child: Text(
                                    'ACK',
                                    style: text.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kAuthRedLink,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _greetingPrefix(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _actionCard(
    TextStyle text, {
    required IconData icon,
    required Color iconColor,
    required Color tint,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kAuthCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kAuthBorder),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: text.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kAuthText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: text.copyWith(fontSize: 11, color: kAuthFaint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color tint,
  }) {
    final text = GoogleFonts.inter();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
        decoration: BoxDecoration(
          color: kAuthCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kAuthBorder),
          boxShadow: kCardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: text.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: kAuthText,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: text.copyWith(fontSize: 11, color: kAuthFaint),
            ),
          ],
        ),
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
                initialValue: selectedSessionId,
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
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed:
                  selectedSessionId == null || messageCtrl.text.trim().isEmpty
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

  Future<void> _sendDriverMessage(BuildContext context, int sessionId,
      String title, String message) async {
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
}