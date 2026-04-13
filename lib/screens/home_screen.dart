import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import 'training_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StatsService _stats = StatsService();
  final DatabaseService _db = DatabaseService.instance;

  Map<String, dynamic> _homeStats = {
    'todayTotal': 0,
    'streak': 0,
    'bestSet': 0,
    'allTimeBest': 0,
  };
  List<Session> _recentSessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final statsData = await _stats.getHomeStats();
    final recent = await _db.getRecentSessions(3);
    if (mounted) {
      setState(() {
        _homeStats = statsData;
        _recentSessions = recent;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent))
            : RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.surface,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildTitle(),
                      const SizedBox(height: 24),
                      _buildTodayCard(),
                      const SizedBox(height: 16),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildStartButton(),
                      const SizedBox(height: 24),
                      _buildRecentSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'PULLUP TRACKER',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
        letterSpacing: 3,
      ),
    );
  }

  Widget _buildTodayCard() {
    final today = _homeStats['todayTotal'] as int;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withAlpha(30),
            AppColors.surfaceAlt,
          ],
        ),
        border: Border.all(color: AppColors.accent.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Total',
            style: TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$today',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 8),
                child: Text(
                  'pull-ups',
                  style: TextStyle(color: AppColors.textDim, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            '🔥',
            '🔥 ${_homeStats['streak']} days',
            'Streak',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStatCard(
            '🏆',
            'Best ${_homeStats['bestSet']}',
            'Best Set',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStatCard(
            '⭐',
            'All-time ${_homeStats['allTimeBest']}',
            'All-time Best',
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrainingScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.bolt, size: 22),
        label: const Text(
          'Start Training',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection() {
    if (_recentSessions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sessions',
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        ..._recentSessions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _recentRow(s),
            )),
      ],
    );
  }

  Widget _recentRow(Session s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MM-dd HH:mm').format(s.date),
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  '${s.sets.length} sets · ${s.formattedDuration}',
                  style:
                      const TextStyle(color: AppColors.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${s.totalReps} reps',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
