import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sign_result.dart';
import '../state/sign_provider.dart';

/// History screen — shows past translations from backend
/// 🔵 P4 owns visual design; Person 2 provides the data fetching.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<HistoryItem> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final items = await api.getHistory('default');
      setState(() {
        _history = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load history: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _history.isEmpty
                  ? const Center(
                      child: Text(
                        'No translations yet.\nStart translating to see history here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[_history.length - 1 - index];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                item.mode == 'MODE_A'
                                    ? Icons.videocam
                                    : Icons.mic,
                                color: item.mode == 'MODE_A'
                                    ? Colors.orange
                                    : Colors.teal,
                              ),
                              title: Text(item.outputContent),
                              subtitle: Text(
                                item.inputContent,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: Text(
                                item.mode == 'MODE_A' ? 'Sign→Speak' : 'Speak→Sign',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
