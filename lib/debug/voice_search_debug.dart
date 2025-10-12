import 'package:flutter/material.dart';
import '../services/voice_search_service.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceSearchDebugScreen extends StatefulWidget {
  const VoiceSearchDebugScreen({super.key});

  @override
  State<VoiceSearchDebugScreen> createState() => _VoiceSearchDebugScreenState();
}

class _VoiceSearchDebugScreenState extends State<VoiceSearchDebugScreen> {
  String _debugInfo = 'Initializing...';
  bool _isListening = false;
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _debugInfo = 'Running diagnostics...\n';
    });

    // Check permissions
    final microphonePermission = await Permission.microphone.status;
    _debugInfo += 'Microphone permission: $microphonePermission\n';

    // Check if speech recognition is available
    final isAvailable = await VoiceSearchService.isAvailable();
    _debugInfo += 'Speech recognition available: $isAvailable\n';

    // Check if currently listening
    _debugInfo += 'Currently listening: ${VoiceSearchService.isListening}\n';

    setState(() {
      _debugInfo += '\nDiagnostics complete.';
    });
  }

  Future<void> _testVoiceSearch() async {
    setState(() {
      _isListening = true;
      _lastResult = '';
    });

    try {
      final result = await VoiceSearchService.startListening(
        timeout: const Duration(seconds: 10),
      );

      setState(() {
        _isListening = false;
        _lastResult = result ?? 'No result';
      });
    } catch (e) {
      setState(() {
        _isListening = false;
        _lastResult = 'Error: $e';
      });
    }
  }

  Future<void> _stopListening() async {
    await VoiceSearchService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Search Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Information:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Result: $_lastResult',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isListening ? _stopListening : _testVoiceSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isListening ? 'Stop Listening' : 'Start Voice Search'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runDiagnostics,
                    child: const Text('Refresh Diagnostics'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
