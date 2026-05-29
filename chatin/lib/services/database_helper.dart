import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chatin.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Buat tabel chat_sessions
    await db.execute('''
      CREATE TABLE chat_sessions(
        id TEXT PRIMARY KEY,
        agent_id TEXT,
        title TEXT,
        user_id TEXT,
        created_at INTEGER
      )
    ''');

    // Buat tabel chat_messages
    await db.execute('''
      CREATE TABLE chat_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        role TEXT,
        content TEXT,
        created_at INTEGER,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  // CRUD chat_sessions
  // ==========================================

  Future<void> createSession(String id, String agentId, String title, String userId) async {
    final db = await database;
    await db.insert(
      'chat_sessions',
      {
        'id': id,
        'agent_id': agentId,
        'title': title,
        'user_id': userId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSessions(String userId) async {
    final db = await database;
    return await db.query(
      'chat_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC', // Urutkan dari yang terbaru
    );
  }

  Future<void> updateSessionTitle(String id, String newTitle) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // CRUD chat_messages
  // ==========================================

  Future<void> insertMessage(String sessionId, String role, String content) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      {
        'session_id': sessionId,
        'role': role,
        'content': content,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) async {
    final db = await database;
    return await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC', // Urutkan dari yang terlama ke terbaru (untuk UI Chat)
    );
  }
}
