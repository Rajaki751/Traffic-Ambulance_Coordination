import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    if (_selected != null &&
        !ambulances.any((a) => a.ambulanceId == _selected!.ambulanceId)) {
      _selected = null;
    }
    final selected =
        _selected ?? (ambulances.isNotEmpty ? ambulances.first : null);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackdrop(
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (ambulances.isEmpty)
                      const AuthEmptyState(
                        icon: Icons.map_rounded,
                        title: 'No active ambulances',
                        hint:
                            'Alerts appear here as soon as a driver starts an '
                            'emergency trip.',
                      )
                    else
                      AmbulanceMap(
                        ambulanceLat: selected?.latitude,
                        ambulanceLon: selected?.longitude,
                        destLat: selected?.destLat,
                        destLon: selected?.destLon,
                        routePolyline: selected?.routePolyline,
                        extraAmbulances: ambulances
                            .where(
                                (a) => a.ambulanceId != selected?.ambulanceId)
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
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GlassSurface(
                        radius: 14,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: kAuthRedBadgeBg,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                size: 16,
                                color: kAuthRedLink,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live map',
                                  style: GoogleFonts.inter().copyWith(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: kAuthText,
                                  ),
                                ),
                                Text(
                                  '${ambulances.length} ambulance'
                                  '${ambulances.length == 1 ? '' : 's'} active',
                                  style: GoogleFonts.inter().copyWith(
                                    fontSize: 11,
                                    color: kAuthFaint,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: kAuthCard,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: kAuthBorder),
                        ),
                        child: InkWell(
                          onTap: live.refresh,
                          customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: kAuthMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (live.error != null)
                      Positioned(
                        top: 66,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: kAuthOrangeTint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kAuthOrange.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: kAuthOrange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  live.error!,
                                  style: GoogleFonts.inter().copyWith(
                                    fontSize: 12.5,
                                    color: kAuthText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (ambulances.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: ambulances.length,
                    itemBuilder: (_, i) {
                      final a = ambulances[i];
                      final isSelected = selected?.ambulanceId == a.ambulanceId;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _ambulanceChip(a, isSelected),
                      );
                    },
                  ),
                ),
              ],
              if (selected != null) _buildDirectionsCard(selected),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: GlassSurface(
                  radius: 16,
                  padding: const EdgeInsets.all(12),
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
                          onPressed:
                              junctions.loading || _selectedJunction == null
                                  ? null
                                  : () => context
                                      .read<JunctionProvider>()
                                      .clearJunction(
                                        junction: _selectedJunction!,
                                        emergencySessionId:
                                            selected?.emergencySessionId,
                                      ),
                          icon: const Icon(Icons.traffic_rounded),
                          label: const Text('Mark junction cleared'),
                        ),
                      ),
                      if (junctions.message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                junctions.message!.endsWith('marked cleared')
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                size: 14,
                                color: junctions.message!
                                        .endsWith('marked cleared')
                                    ? kAuthGreen
                                    : kAuthRed,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  junctions.message!,
                                  style: GoogleFonts.inter().copyWith(
                                    fontSize: 12,
                                    color: junctions.message!
                                            .endsWith('marked cleared')
                                        ? kAuthGreenText
                                        : kAuthRedBadgeText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ambulanceChip(LiveAmbulanceModel a, bool isSelected) {
    final text = GoogleFonts.inter();
    return InkWell(
      onTap: () => setState(() => _selected = a),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? kAuthRedBadgeBg : kAuthCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kAuthRed : kAuthBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_shipping_rounded,
              size: 14,
              color: kAuthRed,
            ),
            const SizedBox(width: 6),
            Text(
              a.vehicleNumber,
              style: text.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isSelected ? kAuthRedBadgeText : kAuthMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionsCard(LiveAmbulanceModel a) {
    final text = GoogleFonts.inter();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GlassSurface(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kAuthRedBadgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    size: 20,
                    color: kAuthRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a.vehicleNumber} • EMERGENCY',
                        style: text.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: kAuthRedBadgeText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'To: ${a.destination}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.copyWith(
                          fontSize: 12.5,
                          color: kAuthMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: kAuthBorder.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    text,
                    label: 'ETA',
                    value: '${formatEta(a.etaMinutes)} min',
                    color: kAuthBlue,
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: kAuthBorder.withValues(alpha: 0.6),
                ),
                Expanded(
                  child: _statTile(
                    text,
                    label: 'Speed',
                    value: '${a.speedKmh?.toStringAsFixed(0) ?? "?"} km/h',
                    color: kAuthGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: kAuthFaint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Clear the route corridor and prioritize this '
                    'ambulance at intersections.',
                    style: text.copyWith(
                      fontSize: 12,
                      height: 1.35,
                      color: kAuthFaint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(
    TextStyle text, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: text.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: text.copyWith(fontSize: 11, color: kAuthFaint),
        ),
      ],
    );
  }
}
