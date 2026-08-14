import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/junction_provider.dart';
import '../widgets/auth_widgets.dart';

class OfficerHistoryScreen extends StatefulWidget {
  const OfficerHistoryScreen({super.key});

  @override
  State<OfficerHistoryScreen> createState() => _OfficerHistoryScreenState();
}

class _OfficerHistoryScreenState extends State<OfficerHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JunctionProvider>().loadClearanceHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final junctions = context.watch<JunctionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Junction Clearance History')),
      body: junctions.loading
          ? const Center(child: CircularProgressIndicator())
          : junctions.clearanceHistory.isEmpty
              ? const AuthEmptyState(
                  icon: Icons.traffic_rounded,
                  title: 'No clearances yet',
                  hint:
                      'Mark junctions cleared from the Live map tab and they '
                      'will show up here with timestamps.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: junctions.clearanceHistory.length,
                  itemBuilder: (_, i) {
                    final h = junctions.clearanceHistory[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.traffic, color: kAuthGreen),
                        title: Text(h.junctionName),
                        subtitle: Text(
                          h.clearedAt.isNotEmpty ? 'Cleared at ${h.clearedAt.substring(0, 19).replaceAll('T', ' ')}' : '',
                        ),
                        trailing: const Icon(Icons.check_circle, color: kAuthGreen),
                      ),
                    );
                  },
                ),
    );
  }
}
