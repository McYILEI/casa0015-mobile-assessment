import '../models/session.dart';
import 'database_service.dart';

class StatsService {
  final DatabaseService _db = DatabaseService.instance;

  Future<Map<String, dynamic>> getHomeStats() async {
    final sessions = await _db.getAllSessions();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todaySessions = sessions
        .where((s) => s.date.isAfter(todayStart) || _isSameDay(s.date, now))
        .toList();

    final todayTotal = todaySessions.fold(0, (sum, s) => sum + s.totalReps);
    final streak = _calculateStreak(sessions, now);
    final bestSet = sessions.isEmpty
        ? 0
        : sessions.map((s) => s.bestSet).reduce((a, b) => a > b ? a : b);
    final allTimeBest = sessions.isEmpty
        ? 0
        : sessions.map((s) => s.totalReps).reduce((a, b) => a > b ? a : b);

    return {
      'todayTotal': todayTotal,
      'streak': streak,
      'bestSet': bestSet,
      'allTimeBest': allTimeBest,
    };
  }

  Future<Map<String, dynamic>> getStatsPageData() async {
    final sessions = await _db.getAllSessions();
    final now = DateTime.now();

    // Week total (last 7 days)
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final weekSessions =
        sessions.where((s) => !s.date.isBefore(weekStart)).toList();
    final weekTotal = weekSessions.fold(0, (sum, s) => sum + s.totalReps);

    final avgPerSession = sessions.isEmpty
        ? 0.0
        : sessions.map((s) => s.totalReps).fold(0, (a, b) => a + b) /
            sessions.length;

    final cumulativeTotal =
        sessions.fold(0, (sum, s) => sum + s.totalReps);

    // Last 7 days bar data
    final barData = <DateTime, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      barData[day] = 0;
    }
    for (final s in weekSessions) {
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      barData[day] = (barData[day] ?? 0) + s.totalReps;
    }

    // Last 30 sessions line data
    final recent30 = sessions.take(30).toList().reversed.toList();

    return {
      'weekTotal': weekTotal,
      'avgPerSession': avgPerSession,
      'cumulativeTotal': cumulativeTotal,
      'sessionCount': sessions.length,
      'barData': barData,
      'recent30': recent30,
    };
  }

  int _calculateStreak(List<Session> sessions, DateTime now) {
    if (sessions.isEmpty) return 0;

    final days = sessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (days.isEmpty) return 0;
    if (days.first != today && days.first != yesterday) return 0;

    int streak = 1;
    for (int i = 1; i < days.length; i++) {
      final expected = days[i - 1].subtract(const Duration(days: 1));
      if (days[i] == expected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
