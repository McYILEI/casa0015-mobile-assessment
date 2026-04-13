import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  static DatabaseService get instance => _instance;
  DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pullup_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            total_reps INTEGER NOT NULL,
            duration INTEGER NOT NULL,
            best_set INTEGER NOT NULL,
            sets TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertSession(Session session) async {
    final db = await database;
    final map = session.toMap()..remove('id');
    final id = await db.insert('sessions', map);
    // Keep only the most recent 200 records
    await db.execute('''
      DELETE FROM sessions WHERE id NOT IN (
        SELECT id FROM sessions ORDER BY date DESC LIMIT 200
      )
    ''');
    return id;
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'date DESC');
    return maps.map(Session.fromMap).toList();
  }

  Future<List<Session>> getRecentSessions(int limit) async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'date DESC', limit: limit);
    return maps.map(Session.fromMap).toList();
  }

  Future<List<Session>> getSessionsForDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );
    return maps.map(Session.fromMap).toList();
  }

  Future<void> deleteAllSessions() async {
    final db = await database;
    await db.delete('sessions');
  }
}
