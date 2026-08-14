import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/route_utils.dart';
import '../models/emergency_model.dart';
import 'auth_widgets.dart';

class DirectionsPanel extends StatelessWidget {
  final String? routePolyline;
  final double? totalEtaMinutes;
  final List<RouteStepModel>? routeSteps;

  const DirectionsPanel({
    super.key,
    this.routePolyline,
    this.totalEtaMinutes,
    this.routeSteps,
  });

  @override
  Widget build(BuildContext context) {
    final points = parseRoutePolyline(routePolyline);
    final dist = Distance();
    final steps = <_StepItem>[];
    double total = 0;

    if (routeSteps != null && routeSteps!.isNotEmpty) {
      // Use provided OSRM steps for better instructions
      for (var i = 0; i < routeSteps!.length; i++) {
        final s = routeSteps![i];
        steps.add(_StepItem(index: i + 1, lat: 0, lon: 0, meters: s.distanceM));
        total += s.distanceM;
      }
    } else {
      for (var i = 0; i < points.length; i++) {
        if (i == 0) continue;
        final prev = points[i - 1];
        final curr = points[i];
        final d = dist.as(LengthUnit.Meter, prev, curr);
        total += d;
        steps.add(_StepItem(
            index: i, lat: curr.latitude, lon: curr.longitude, meters: d));
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 48,
              decoration: BoxDecoration(
                  color: kAuthBorder, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions, color: kAuthRed),
                const SizedBox(width: 8),
                const Text('Turn-by-turn (approx.)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (totalEtaMinutes != null)
                  Text('${totalEtaMinutes!.round()} min',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            if (steps.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No directions available for this route.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: steps.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (_, i) {
                    final s = steps[i];
                    final cumMeters = steps
                        .take(i + 1)
                        .fold<double>(0, (p, e) => p + e.meters);
                    final eta = totalEtaMinutes != null && total > 0
                        ? (cumMeters / total) * totalEtaMinutes!
                        : null;
                    final instr = (routeSteps != null && routeSteps!.length > i)
                        ? routeSteps![i].instruction
                        : 'Proceed ${(s.meters).round()} m';
                    return ListTile(
                      leading: CircleAvatar(child: Text('${s.index}')),
                      title: Text(instr),
                      subtitle: routeSteps != null && routeSteps!.length > i
                          ? Text('${(s.meters).round()} m')
                          : Text(
                              'Lat ${s.lat.toStringAsFixed(5)}, Lon ${s.lon.toStringAsFixed(5)}'),
                      trailing: eta != null ? Text('${eta.round()}m') : null,
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StepItem {
  final int index;
  final double lat;
  final double lon;
  final double meters;

  _StepItem(
      {required this.index,
      required this.lat,
      required this.lon,
      required this.meters});
}
