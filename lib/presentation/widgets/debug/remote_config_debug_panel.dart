import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/infrastructure/services/firebase_services_manager.dart';

class RemoteConfigDebugPanel extends StatefulWidget {
  const RemoteConfigDebugPanel({super.key});

  @override
  State<RemoteConfigDebugPanel> createState() => _RemoteConfigDebugPanelState();
}

class _RemoteConfigDebugPanelState extends State<RemoteConfigDebugPanel> {
  bool? _featureTrivia;
  String? _bannerText;
  int? _markersLimit;
  String _status = '';

  Future<void> _refresh() async {
    try {
      setState(() => _status = 'Actualizando...');
      // Forzar fetchAndActivate en debug para ver cambios rápidos
      await FirebaseServicesManager.instance.configureRemoteConfig();
      final rc = FirebaseServicesManager.instance.remoteConfig;
      setState(() {
        _featureTrivia = rc?.getBool('feature_trivia_enabled');
        _bannerText = rc?.getString('home_banner_text');
        _markersLimit = rc?.getInt('map_markers_limit');
        _status = 'OK';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Remote Config', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(_status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                )
              ],
            ),
            const SizedBox(height: 8),
            Text('feature_trivia_enabled: ${_featureTrivia ?? '-'}'),
            Text('home_banner_text: ${_bannerText ?? '-'}'),
            Text('map_markers_limit: ${_markersLimit ?? '-'}'),
          ],
        ),
      ),
    );
  }
}


