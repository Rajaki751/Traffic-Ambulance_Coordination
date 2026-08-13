import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/emergency_provider.dart';
import '../providers/live_ambulance_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/route_utils.dart';
import '../widgets/directions_panel.dart';
import '../widgets/ambulance_map.dart';
import '../widgets/emergency_button.dart';
import 'emergency_activate_screen.dart';
import 'navigation_screen.dart';
import 'driver_updates_screen.dart';
import 'profile_screen.dart';

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
    final auth = context.watch<AuthProvider>();
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
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          if (emergency.isEmergencyActive)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('EMERGENCY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == 1 && !emergency.isEmergencyActive) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyActivateScreen()),
            ).then((_) async {
              if (!context.mounted) return;
              if (emergency.isEmergencyActive && emergency.activeEmergency != null) {
                await context.read<DriverLocationProvider>().startTracking(
                      emergency.activeEmergency!.id,
                      onTick: emergency.refreshActiveEmergency,
                    );
                if (!context.mounted) return;
                setState(() => _driverStatus = 'Busy');
              }
            });
            return;
          }
          setState(() => _selectedIndex = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
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
    return RefreshIndicator(
      onRefresh: () async {
        await emergency.restoreActiveSession();
        await notifs.load();
        await emergency.loadHistory();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: emergency.isEmergencyActive
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          emergency.isEmergencyActive ? 'Busy' : _driverStatus,
                          style: TextStyle(
                            color: emergency.isEmergencyActive ? Colors.red : Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!emergency.isEmergencyActive) ...[
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Available', label: Text('Available'), icon: Icon(Icons.check_circle_outline)),
                        ButtonSegment(value: 'On Duty', label: Text('On Duty'), icon: Icon(Icons.work_outline)),
                        ButtonSegment(value: 'Offline', label: Text('Offline'), icon: Icon(Icons.offline_bolt_outlined)),
                      ],
                      selected: {_driverStatus},
                      onSelectionChanged: (s) async {
                        final newStatus = s.first;
                        setState(() => _driverStatus = newStatus);
                        final apiStatus = newStatus == 'Available'
                            ? 'available'
                            : newStatus == 'On Duty'
                                ? 'on_duty'
                                : 'offline';
                        await context.read<AuthProvider>().updateAmbulanceStatus(apiStatus);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.local_shipping,
                  label: 'Active Emergency',
                  value: emergency.isEmergencyActive ? 'Yes' : 'No',
                  color: emergency.isEmergencyActive ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.check_circle,
                  label: 'Today\'s Trips',
                  value: '$todayTrips',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.notifications,
                  label: 'Notifications',
                  value: '${notifs.unreadCount}',
                  color: notifs.unreadCount > 0 ? Colors.orange : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.speed,
                  label: 'Speed',
                  value: active != null
                      ? '${location.speedKmh != null ? location.speedKmh!.toStringAsFixed(0) : "—"} km/h'
                      : '— km/h',
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (emergency.isEmergencyActive && active != null) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emergency, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Active Emergency',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _infoRow('Destination', active.destination),
                    _infoRow('ETA', '${formatEta(active.etaMinutes)} min'),
                    _infoRow('Type', active.incidentType ?? 'general'),
                    _infoRow('Priority', active.priorityLevel ?? 'standard'),
                    if (active.patientName != null) _infoRow('Patient', active.patientName!),
                    if (active.hospitalName != null) _infoRow('Hospital', active.hospitalName!),
                    if (active.tripStage != null) _infoRow('Stage', active.tripStage!.replaceAll('_', ' ').toUpperCase()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (!emergency.isEmergencyActive)
            EmergencyButton(
              loading: emergency.loading,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyActivateScreen()),
                );
                if (!context.mounted) return;
                if (emergency.isEmergencyActive && emergency.activeEmergency != null) {
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
                    label: const Text('End Emergency'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: emergency.loading
                        ? null
                        : () async {
                            final ok = await emergency.endEmergency();
                            if (!context.mounted) return;
                            if (ok) {
                              context.read<DriverLocationProvider>().stopTracking();
                              setState(() => _driverStatus = 'Available');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    emergency.error ?? 'Failed to end emergency',
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
                _stageButton(context, emergency, 'arrived_patient', 'Arrived at Patient'),
                _stageButton(context, emergency, 'patient_picked_up', 'Patient Picked Up'),
                _stageButton(context, emergency, 'arrived_hospital', 'Reached Hospital'),
              ],
            ),
          ],
        ],
      ),
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
            color: AppTheme.emergencyRed,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'EN ROUTE — ETA ${formatEta(active?.etaMinutes)} min',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
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
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
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
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                      label: const Text('ACTIVATE EMERGENCY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emergencyRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmergencyActivateScreen()),
                        );
                        if (!context.mounted) return;
                        if (emergency.isEmergencyActive && emergency.activeEmergency != null) {
                          await context.read<DriverLocationProvider>().startTracking(
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

  Widget _statCard(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _stageButton(BuildContext context, EmergencyProvider emergency, String stage, String label) {
    return OutlinedButton(
      onPressed: emergency.loading ? null : () => context.read<EmergencyProvider>().updateTripStage(stage),
      child: Text(label),
    );
  }
}
