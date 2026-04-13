import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/session_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sessions = await DatabaseService.instance.getAllSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Training History'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _sessions.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: _sessions.length,
                    itemBuilder: (_, i) => SessionTile(session: _sessions[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center, color: AppColors.textDim, size: 56),
          SizedBox(height: 16),
          Text(
            'No training records yet',
            style: TextStyle(color: AppColors.textDim, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Start your first training session!',
            style: TextStyle(color: AppColors.border, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
