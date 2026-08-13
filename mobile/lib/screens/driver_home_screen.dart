import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/emergency_provider.dart';
import '../providers/live_ambulance_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/route_utils.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/directions_panel.dart';
import '../widgets/ambulance_map.dart';
import '../widgets/emergency_button.dart';
import 'emergency_activate_screen.dart';
import 'navigation_screen.dart';
import 'driver_updates_screen.dart';
import 'profile_screen.dart';

const _kGreenBadgeBg = Color(0xFFE8F5EC);
const _kGreenBadgeText = Color(0xFF1F7A44);
const _kBlue = Color(0xFF2E6FD8);
const _kGreen = Color(0xFF2F9E63);
const _kOrange = Color(0xFFE8833A);
const _kNeutralTint = Color(0xFFF2F1ED);
const _kBlueTint = Color(0xFFEAF1FC);
const _kOrangeTint = Color(0xFFFDF1E7);

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;
  String _driverStatus = 'Available';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loc = context.read<DriverLocationProvider>();
      final emergency = context.read<EmergencyProvider>();
      final notifications = context.read<NotificationProvider>();
      await loc.init();
      await emergency.restoreActiveSession();
      await notifications.setMode(driver: true);
      if (emergency.isEmergencyActive && emergency.activeEmergency != null) {
        final started = await loc.startTracking(
          emergency.activeEmergency!.id,
          onTick: emergency.refreshActiveEmergency,
        );
        if (!started && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission required for live tracking'),
            ),
          );
        }
        if (mounted) setState(() => _driverStatus = 'Busy');
      }
      await emergency.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyProvider>();
    final location = context.watch<DriverLocationProvider>();
    final notifs = context.watch<NotificationProvider>();
    final active = emergency.activeEmergency;
    final now = DateTime.now();
    bool isToday(DateTime dt) =>
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final todayTrips = emergency.history
        .where((h) =>
            isToday(h.startedAt) || (h.endedAt != null && isToday(h.endedAt!)))
        .length;

    final pages = <Widget>[
      _buildHomePage(context, emergency, location, active, todayTrips, notifs),
      _buildMapPage(context, emergency, location, active),
      const DriverUpdatesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: kAuthBg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: pages[_selectedIndex],
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
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _navItem(
                  index: 1,
                  icon: Icons.route_rounded,
                  label: 'Trips',
                ),
                _navItem(
                  index: 2,
                  icon: Icons.notifications_rounded,
                  label: 'Alerts',
                ),
                _navItem(
                  index: 3,
                  icon: Icons.person_rounded,
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
    required String label,
  }) {
    final active = _selectedIndex == index;
    final color = active ? kAuthRedLink : kAuthIcon;
    final text = GoogleFonts.inter();
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: text.copyWith(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage(
    BuildContext context,
    EmergencyProvider emergency,
    DriverLocationProvider location,
    dynamic active,
    int todayTrips,
    NotificationProvider notifs,
  ) {
    final text = GoogleFonts.inter();
    final auth = context.watch<AuthProvider>();
    final driverName = auth.user?.name.trim() ?? '';
    final firstName = driverName.isEmpty
        ? 'Driver'
        : driverName.split(' ').first;
    return RefreshIndicator(
      onRefresh: () async {
        await emergency.restoreActiveSession();
        await notifs.load();
        await emergency.loadHistory();
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
                      'Driver dashboard',
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
                  border: Border.all(color: kAuthRed.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    firstName.isEmpty ? 'D' : firstName[0].toUpperCase(),
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1A1A18),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: emergency.isEmergencyActive
                            ? kAuthRedBadgeBg
                            : _kGreenBadgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        emergency.isEmergencyActive
                            ? Icons.local_hospital_rounded
                            : Icons.check_circle_rounded,
                        size: 20,
                        color: emergency.isEmergencyActive
                            ? kAuthRedBadgeText
                            : _kGreenBadgeText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My status',
                            style: text.copyWith(
                              fontSize: 12.5,
                              color: kAuthFaint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emergency.isEmergencyActive
                                ? 'Busy'
                                : _driverStatus,
                            style: text.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: kAuthText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!emergency.isEmergencyActive) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statusPill(
                        icon: Icons.check_circle_outline,
                        label: 'Available',
                        active: _driverStatus == 'Available',
                        onTap: () => _setStatus('Available', 'available'),
                      ),
                      const SizedBox(width: 8),
                      _statusPill(
                        icon: Icons.work_outline,
                        label: 'On duty',
                        active: _driverStatus == 'On Duty',
                        onTap: () => _setStatus('On Duty', 'on_duty'),
                      ),
                      const SizedBox(width: 8),
                      _statusPill(
                        icon: Icons.offline_bolt_outlined,
                        label: 'Offline',
                        active: _driverStatus == 'Offline',
                        onTap: () => _setStatus('Offline', 'offline'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                icon: Icons.local_shipping,
                label: 'Active emergency',
                value: emergency.isEmergencyActive ? 'Yes' : 'No',
                iconColor: emergency.isEmergencyActive
                    ? kAuthRed
                    : kAuthMuted,
                tint: emergency.isEmergencyActive
                    ? kAuthRedBadgeBg
                    : _kNeutralTint,
              ),
              const SizedBox(width: 12),
              _statCard(
                icon: Icons.check_circle,
                label: "Today's trips",
                value: '$todayTrips',
                iconColor: _kBlue,
                tint: _kBlueTint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                icon: Icons.notifications,
                label: 'Notifications',
                value: '${notifs.unreadCount}',
                iconColor: notifs.unreadCount > 0 ? _kOrange : kAuthMuted,
                tint: notifs.unreadCount > 0
                    ? _kOrangeTint
                    : _kNeutralTint,
              ),
              const SizedBox(width: 12),
              _statCard(
                icon: Icons.speed,
                label: 'Speed',
                value: active != null
                    ? '${location.speedKmh != null ? location.speedKmh!.toStringAsFixed(0) : "—"} km/h'
                    : '— km/h',
                iconColor: _kGreen,
                tint: _kGreenBadgeBg,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (emergency.isEmergencyActive && active != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kAuthRedBadgeBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kAuthRed.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emergency, size: 20, color: kAuthRed),
                      const SizedBox(width: 8),
                      Text(
                        'Active emergency',
                        style: text.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kAuthRedBadgeText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: kAuthRed.withOpacity(0.25),
                  ),
                  const SizedBox(height: 6),
                  _infoRow('Destination', active.destination),
                  _infoRow('ETA', '${formatEta(active.etaMinutes)} min'),
                  _infoRow('Type', active.incidentType ?? 'general'),
                  _infoRow('Priority', active.priorityLevel ?? 'standard'),
                  if (active.patientName != null)
                    _infoRow('Patient', active.patientName!),
                  if (active.hospitalName != null)
                    _infoRow('Hospital', active.hospitalName!),
                  if (active.tripStage != null)
                    _infoRow('Stage', _capitalize(active.tripStage!)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

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
              const Expanded(
                child: Divider(color: kAuthBorder, height: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!emergency.isEmergencyActive)
            EmergencyButton(
              loading: emergency.loading,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmergencyActivateScreen()),
                );
                if (!context.mounted) return;
                if (emergency.isEmergencyActive &&
                    emergency.activeEmergency != null) {
                  await context.read<DriverLocationProvider>().startTracking(
                        emergency.activeEmergency!.id,
                        onTick: emergency.refreshActiveEmergency,
                      );
                  if (!context.mounted) return;
                  setState(() => _driverStatus = 'Busy');
                }
              },
            ),

          if (emergency.isEmergencyActive) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text('Open Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                onPressed: active != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NavigationScreen(),
                          ),
                        );
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('Directions'),
                    style: _outlineStyle(),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => DirectionsPanel(
                        routePolyline: active?.routePolyline,
                        totalEtaMinutes: active?.etaMinutes,
                        routeSteps: active?.routeSteps,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('End emergency'),
                    style: _outlineStyle(
                      foregroundColor: kAuthRed,
                      borderColor: kAuthRed.withOpacity(0.4),
                    ),
                    onPressed: emergency.loading
                        ? null
                        : () async {
                            final ok = await emergency.endEmergency();
                            if (!context.mounted) return;
                            if (ok) {
                              context
                                  .read<DriverLocationProvider>()
                                  .stopTracking();
                              setState(() => _driverStatus = 'Available');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    emergency.error ??
                                        'Failed to end emergency',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _stageButton(context, emergency, 'arrived_patient',
                    'Arrived at Patient'),
                _stageButton(context, emergency, 'patient_picked_up',
                    'Patient Picked Up'),
                _stageButton(context, emergency, 'arrived_hospital',
                    'Reached Hospital'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _greetingPrefix(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _setStatus(String display, String api) async {
    setState(() => _driverStatus = display);
    await context.read<AuthProvider>().updateAmbulanceStatus(api);
  }

  Widget _statusPill({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final text = GoogleFonts.inter();
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: active ? kAuthRedBadgeBg : kAuthCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? kAuthRed : kAuthBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? kAuthRedBadgeText : kAuthFaint,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: text.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? kAuthRedBadgeText : kAuthFaint,
                ),
              ),
            ],
          ),
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A1A1A18),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
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

  ButtonStyle _outlineStyle({
    Color? foregroundColor,
    Color? borderColor,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor ?? kAuthText,
      backgroundColor: kAuthCard,
      side: BorderSide(color: borderColor ?? kAuthBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  Widget _buildMapPage(
    BuildContext context,
    EmergencyProvider emergency,
    DriverLocationProvider location,
    dynamic active,
  ) {
    return Column(
      children: [
        if (emergency.isEmergencyActive)
          Container(
            width: double.infinity,
            color: kAuthRed,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'En route — ETA ${formatEta(active?.etaMinutes)} min',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              AmbulanceMap(
                ambulanceLat: location.lat,
                ambulanceLon: location.lon,
                destLat: active?.destLat,
                destLon: active?.destLon,
                routePolyline: active?.routePolyline,
                showTrafficOverlay: true,
              ),
              if (emergency.isEmergencyActive && active != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.navigation),
                          label: const Text('Start Navigation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NavigationScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.list, size: 18),
                              label: const Text('Directions'),
                              style: _outlineStyle(),
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => DirectionsPanel(
                                  routePolyline: active?.routePolyline,
                                  totalEtaMinutes: active?.etaMinutes,
                                  routeSteps: active?.routeSteps,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.stop, size: 18),
                              label: const Text('End'),
                              style: _outlineStyle(
                                foregroundColor: kAuthRed,
                                borderColor: kAuthRed.withOpacity(0.4),
                              ),
                              onPressed: emergency.loading
                                  ? null
                                  : () async {
                                      final ok = await emergency
                                          .endEmergency();
                                      if (!context.mounted) return;
                                      if (ok) {
                                        context
                                            .read<DriverLocationProvider>()
                                            .stopTracking();
                                        setState(
                                            () => _driverStatus = 'Available');
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              emergency.error ??
                                                  'Failed to end emergency',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (!emergency.isEmergencyActive)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.emergency),
                      label: const Text('Activate emergency'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAuthRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EmergencyActivateScreen()),
                        );
                        if (!context.mounted) return;
                        if (emergency.isEmergencyActive &&
                            emergency.activeEmergency != null) {
                          await context.read<DriverLocationProvider>()
                              .startTracking(
                                emergency.activeEmergency!.id,
                                onTick: emergency.refreshActiveEmergency,
                              );
                          if (!context.mounted) return;
                          setState(() => _driverStatus = 'Busy');
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    final text = GoogleFonts.inter();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: text.copyWith(color: kAuthFaint, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: text.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: kAuthText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String input) {
    final parts = input.replaceAll('_', ' ').split(' ');
    return parts
        .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  Widget _stageButton(
    BuildContext context,
    EmergencyProvider emergency,
    String stage,
    String label,
  ) {
    return OutlinedButton(
      onPressed: emergency.loading
          ? null
          : () => context.read<EmergencyProvider>().updateTripStage(stage),
      style: _outlineStyle(),
      child: Text(label),
    );
  }
}