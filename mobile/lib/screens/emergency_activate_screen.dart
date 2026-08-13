import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/kathmandu.dart';
import '../providers/emergency_provider.dart';
import '../services/api_service.dart';
import '../services/geocoding_service.dart';

class EmergencyActivateScreen extends StatefulWidget {
  const EmergencyActivateScreen({super.key});

  @override
  State<EmergencyActivateScreen> createState() => _EmergencyActivateScreenState();
}

class _EmergencyActivateScreenState extends State<EmergencyActivateScreen> {
  final _destCtrl = TextEditingController(text: 'Emergency incident');
  final _latCtrl = TextEditingController(text: KathmanduLocation.centerLat.toString());
  final _lonCtrl = TextEditingController(text: KathmanduLocation.centerLon.toString());
  bool _useAi = true;
  String _incidentType = 'general';
  String _routePreference = 'fastest';
  KathmanduHospital? _hospital = kathmanduHospitals.first;

  static const _incidentTypes = [
    'general',
    'accident',
    'cardiac',
    'fire',
    'respiratory',
    'trauma',
  ];

  @override
  void dispose() {
    _destCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  void _showLocationSearch(BuildContext context) {
    final searchCtrl = TextEditingController();
    List<GeocodingResult>? results;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Search Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'e.g. Teaching Hospital Kathmandu',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    onPressed: () async {
                      if (searchCtrl.text.trim().length < 2) return;
                      setDialogState(() => loading = true);
                      try {
                        final api = context.read<ApiService?>();
                        if (api == null) return;
                        final svc = GeocodingService(api);
                        final r = await svc.search(
                          searchCtrl.text.trim(),
                          lat: 27.7172,
                          lon: 85.3240,
                        );
                        setDialogState(() {
                          results = r;
                          loading = false;
                        });
                      } catch (e) {
                        setDialogState(() => loading = false);
                      }
                    },
                  ),
                ),
                onSubmitted: (_) async {
                  if (searchCtrl.text.trim().length < 2) return;
                  setDialogState(() => loading = true);
                  try {
                    final api = context.read<ApiService?>();
                    if (api == null) return;
                    final svc = GeocodingService(api);
                    final r = await svc.search(
                      searchCtrl.text.trim(),
                      lat: 27.7172,
                      lon: 85.3240,
                    );
                    setDialogState(() {
                      results = r;
                      loading = false;
                    });
                  } catch (e) {
                    setDialogState(() => loading = false);
                  }
                },
              ),
              const SizedBox(height: 12),
              if (loading) const CircularProgressIndicator(),
              if (!loading && results != null && results!.isEmpty)
                const Text('No results found', style: TextStyle(color: Colors.grey)),
              if (!loading && results != null && results!.isNotEmpty)
                SizedBox(
                  height: 250,
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results!.length,
                    itemBuilder: (_, i) {
                      final r = results![i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, color: Colors.red),
                        title: Text(
                          r.displayName.split(',').take(2).join(','),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          _destCtrl.text = r.displayName.split(',').take(2).join(',');
                          _latCtrl.text = r.latitude.toStringAsFixed(6);
                          _lonCtrl.text = r.longitude.toStringAsFixed(6);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _predictionRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyProvider>();
    final prediction = emergency.lastPrediction;

    return Scaffold(
      appBar: AppBar(title: const Text('Activate Emergency')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('AI incident prediction'),
              subtitle: const Text(
                'scikit-learn forecasts incident location; OSRM finds fastest route',
              ),
              value: _useAi,
              onChanged: (v) => setState(() => _useAi = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _incidentType,
              decoration: const InputDecoration(
                labelText: 'Incident type',
                border: OutlineInputBorder(),
              ),
              items: _incidentTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _incidentType = v ?? 'general'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _routePreference,
              decoration: const InputDecoration(
                labelText: 'Route preference',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'fastest', child: Text('Fastest (time)')),
                DropdownMenuItem(value: 'shortest', child: Text('Shortest (distance)')),
              ],
              onChanged: (v) => setState(() => _routePreference = v ?? 'fastest'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _destCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Destination / landmark',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Teaching Hospital, New Baneshwor',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _showLocationSearch(context),
                  icon: const Icon(Icons.search),
                  tooltip: 'Search location',
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<KathmanduHospital>(
              value: _hospital,
              decoration: const InputDecoration(
                labelText: 'Kathmandu hospital (optional)',
                border: OutlineInputBorder(),
              ),
              items: kathmanduHospitals
                  .map((h) => DropdownMenuItem(value: h, child: Text(h.name)))
                  .toList(),
              onChanged: (h) {
                if (h == null) return;
                setState(() => _hospital = h);
                if (!_useAi) {
                  _latCtrl.text = h.lat.toStringAsFixed(6);
                  _lonCtrl.text = h.lon.toStringAsFixed(6);
                }
              },
            ),
            if (!_useAi) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _latCtrl,
                decoration: const InputDecoration(
                  labelText: 'Incident latitude (manual)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Incident longitude (manual)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            if (_useAi) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: emergency.loading
                    ? null
                    : () async {
                        final pred = await emergency.previewAiPrediction(
                          incidentType: _incidentType,
                        );
                        if (pred != null && mounted) {
                          _latCtrl.text = pred.incidentLat.toStringAsFixed(6);
                          _lonCtrl.text = pred.incidentLon.toStringAsFixed(6);
                        }
                      },
                icon: const Icon(Icons.psychology),
                label: const Text('Preview AI prediction'),
              ),
            ],
            if (prediction != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI Prediction Result',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        prediction.incidentDescription,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      _predictionRow(
                        Icons.location_on,
                        'Predicted Location',
                        '${prediction.incidentLat.toStringAsFixed(5)}, ${prediction.incidentLon.toStringAsFixed(5)}',
                      ),
                      _predictionRow(
                        Icons.analytics,
                        'Confidence',
                        '${(prediction.confidence * 100).toStringAsFixed(0)}% — ${prediction.confidenceDescription}',
                      ),
                      _predictionRow(
                        Icons.traffic,
                        'Traffic Condition',
                        prediction.trafficLabel.isNotEmpty ? prediction.trafficLabel : 'Normal',
                      ),
                      _predictionRow(
                        Icons.category,
                        'Incident Type',
                        prediction.incidentType.toUpperCase(),
                      ),
                      _predictionRow(
                        Icons.science,
                        'Model Version',
                        prediction.modelVersion,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (emergency.error != null) ...[
              const SizedBox(height: 12),
              Text(emergency.error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: emergency.loading
                    ? null
                    : () async {
                        final ok = await emergency.activateEmergency(
                          destination: _destCtrl.text,
                          useAiPrediction: _useAi,
                          incidentType: _incidentType,
                          routePreference: _routePreference,
                          destLat: _useAi
                              ? null
                              : double.tryParse(_latCtrl.text),
                          destLon: _useAi
                              ? null
                              : double.tryParse(_lonCtrl.text),
                          hospitalName: _hospital?.name,
                          hospitalLatitude: _hospital?.lat,
                          hospitalLongitude: _hospital?.lon,
                        );
                        if (ok && context.mounted) Navigator.pop(context, true);
                      },
                child: emergency.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('START EMERGENCY', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
