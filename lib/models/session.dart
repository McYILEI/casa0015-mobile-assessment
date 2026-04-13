import 'dart:convert';

class Session {
  final int? id;
  final DateTime date;
  final int totalReps;
  final int duration; // seconds
  final int bestSet;
  final List<int> sets;

  Session({
    this.id,
    required this.date,
    required this.totalReps,
    required this.duration,
    required this.bestSet,
    required this.sets,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total_reps': totalReps,
      'duration': duration,
      'best_set': bestSet,
      'sets': jsonEncode(sets),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      totalReps: map['total_reps'] as int,
      duration: map['duration'] as int,
      bestSet: map['best_set'] as int,
      sets: List<int>.from(jsonDecode(map['sets'] as String) as List),
    );
  }

  String get formattedDuration {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
