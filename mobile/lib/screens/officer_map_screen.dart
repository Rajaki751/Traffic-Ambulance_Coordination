import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_ambulance_model.dart';
import '../providers/junction_provider.dart';
import '../providers/live_ambulance_provider.dart';
import '../services/junction_service.dart';
import '../utils/route_utils.dart';
import '../widgets/ambulance_map.dart';
import '../widgets/auth_widgets.dart';

class OfficerMapScreen extends StatefulWidget {
  const OfficerMapScreen({super.key});

  @override
  State<OfficerMapScreen> createState() => _OfficerMapScreenState();
}

class _OfficerMapScreenState extends State<OfficerMapScreen> {
  LiveAmbulanceModel? _selected;
  JunctionPoint? _selectedJunction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JunctionProvider>().loadKathmanduJunctions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveAmbulanceProvider>();
    final junctions = context.watch<JunctionProvider>();
    final ambulances = live.ambulances;

    if (_selected != null && !ambulances.any((a) => a.ambulanceId == _selected!.ambulanceId)) {
      _selected = null;
    }
    final selected = _selected ?? (ambulances.isNotEmpty ? ambulances.first : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Ambulances'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: live.refresh),
        ],
      ),
      body: Column(
        children: [
          if (live.error != null)
            Material(
              color: kAuthOrangeTint,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(live.error!),
              ),
            ),
          Expanded(
            child: ambulances.isEmpty
                ? const Center(
                    child: Text(
                      'No active ambulances.\nAlerts appear when a driver starts an emergency.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : AmbulanceMap(
                    ambulanceLat: selected?.latitude,
                    ambulanceLon: selected?.longitude,
                    destLat: selected?.destLat,
                    destLon: selected?.destLon,
                    routePolyline: selected?.routePolyline,
                    extraAmbulances: ambulances
                        .where((a) => a.ambulanceId != selected?.ambulanceId)
                        .map(
                          (a) => LiveAmbulanceMarker(
                            lat: a.latitude,
                            lon: a.longitude,
                            label: a.vehicleNumber,
                            routePolyline: a.routePolyline,
                            destLat: a.destLat,
                            destLon: a.destLon,
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (selected != null) _buildDirectionsCard(selected),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAuthCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kAuthBorder),
              boxShadow: kCardShadow,
            ),
            child: Column(
              children: [
                DropdownButtonFormField<JunctionPoint>(
                  initialValue: _selectedJunction,
                  decoration: const InputDecoration(
                    labelText: 'Kathmandu junction to clear',
                    border: OutlineInputBorder(),
                  ),
                  items: junctions.junctions
                      .map(
                        (j) => DropdownMenuItem(
                          value: j,
                          child: Text(j.name),
                        ),
                      )
                      .toList(),
                  onChanged: (j) => setState(() => _selectedJunction = j),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: junctions.loading || _selectedJunction == null
                        ? null
                        : () => context.read<JunctionProvider>().clearJunction(
                              junction: _selectedJunction!,
                              emergencySessionId: selected?.emergencySessionId,
                            ),
                    icon: const Icon(Icons.traffic),
                    label: const Text('Mark Junction Cleared'),
                  ),
                ),
                if (junctions.message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      junctions.message!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (ambulances.length > 1)
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ambulances.length,
                itemBuilder: (_, i) {
                  final a = ambulances[i];
                  final isSelected = selected?.ambulanceId == a.ambulanceId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text(a.vehicleNumber),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selected = a),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectionsCard(LiveAmbulanceModel a) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${a.vehicleNumber} — EMERGENCY',
              style: const TextStyle(fontWeight: FontWeight.w600, color: kAuthRed),
            ),
            const SizedBox(height: 4),
            Text('Heading to: ${a.destination}'),
            Text(
              'ETA: ${formatEta(a.etaMinutes)} min',
              style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
            ),
            Text(
              'Speed: ${a.speedKmh?.toStringAsFixed(0) ?? "?"} km/h',
              style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
            ),
            const SizedBox(height: 8),
            Text(
              'Traffic officer action: Clear the blue/red route corridor and '
              'prioritize this ambulance at intersections.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
