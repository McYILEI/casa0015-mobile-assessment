import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsService _statsService = StatsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _statsService.getStatsPageData();
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All Data', style: TextStyle(color: AppColors.text)),
        content: const Text('This cannot be undone. Delete all training records?',
            style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseService.instance.deleteAllSessions();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stats'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      body: _loading
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
                    const SizedBox(height: 8),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildBarChart(),
                    const SizedBox(height: 24),
                    _buildLineChart(),
                    const SizedBox(height: 32),
                    _buildClearButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    final d = _data!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        StatCard(
          label: 'This Week',
          value: '${d['weekTotal']}',
          icon: Icons.date_range,
          valueColor: AppColors.accent,
        ),
        StatCard(
          label: 'Avg / Session',
          value: (d['avgPerSession'] as double).toStringAsFixed(1),
          icon: Icons.bar_chart,
        ),
        StatCard(
          label: 'Total Reps',
          value: '${d['cumulativeTotal']}',
          icon: Icons.fitness_center,
          valueColor: AppColors.gold,
        ),
        StatCard(
          label: 'Sessions',
          value: '${d['sessionCount']}',
          icon: Icons.event_available,
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final barData = _data!['barData'] as Map<DateTime, int>;
    final entries = barData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxY =
        entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Last 7 Days',
            style: TextStyle(
                color: AppColors.textDim, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              backgroundColor: AppColors.surface,
              barGroups: List.generate(entries.length, (i) {
                final val = entries[i].value.toDouble();
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: val,
                      color: AppColors.accent,
                      width: 22,
                      borderRadius: BorderRadius.circular(6),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY <= 0 ? 10 : maxY * 1.2,
                        color: AppColors.surfaceAlt,
                      ),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= entries.length) return const SizedBox();
                      return Text(
                        DateFormat('M/d').format(entries[i].key),
                        style: const TextStyle(
                            color: AppColors.textDim, fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              maxY: maxY <= 0 ? 10 : maxY * 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final recent30 = _data!['recent30'] as List<Session>;
    if (recent30.isEmpty) return const SizedBox.shrink();

    final totalSpots = <FlSpot>[];
    final bestSpots = <FlSpot>[];

    for (int i = 0; i < recent30.length; i++) {
      totalSpots.add(FlSpot(i.toDouble(), recent30[i].totalReps.toDouble()));
      bestSpots.add(FlSpot(i.toDouble(), recent30[i].bestSet.toDouble()));
    }

    final maxY = recent30
        .map((s) => s.totalReps)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Last 30 Sessions Trend',
            style: TextStyle(
                color: AppColors.textDim, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              backgroundColor: AppColors.surface,
              lineBarsData: [
                LineChartBarData(
                  spots: totalSpots,
                  isCurved: true,
                  color: AppColors.accent,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accent.withAlpha(30),
                  ),
                ),
                LineChartBarData(
                  spots: bestSpots,
                  isCurved: true,
                  color: AppColors.gold,
                  barWidth: 1.5,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 9),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.border,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              maxY: maxY <= 0 ? 10 : maxY * 1.2,
              minY: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(width: 20, height: 2, color: AppColors.accent),
            const SizedBox(width: 6),
            const Text('Total Reps',
                style: TextStyle(color: AppColors.textDim, fontSize: 11)),
            const SizedBox(width: 16),
            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.gold,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text('Best Set',
                style: TextStyle(color: AppColors.textDim, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildClearButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmClear,
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text('Clear All Data'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.warning,
          side: const BorderSide(color: AppColors.warning),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
