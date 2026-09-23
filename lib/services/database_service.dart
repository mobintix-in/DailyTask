import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dailytask.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        dueTime TEXT,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        reminderDateTime TEXT,
        notificationId INTEGER
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        tags TEXT,
        isPinned INTEGER NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  // ================= TASKS OPERATIONS =================

  Future<int> insertTask(TaskModel task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(TaskModel task) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TaskModel>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', orderBy: 'dueDate ASC, dueTime ASC');
    return result.map((json) => TaskModel.fromMap(json)).toList();
  }

  Future<List<TaskModel>> getTasksByDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'dueDate = ?',
      whereArgs: [date],
      orderBy: 'isCompleted ASC, dueTime ASC',
    );
    return result.map((json) => TaskModel.fromMap(json)).toList();
  }

  Future<Map<String, int>> getTodayTaskStats(String todayDate) async {
    final db = await instance.database;
    final total = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM tasks WHERE dueDate = ?',
      [todayDate],
    )) ?? 0;

    final completed = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM tasks WHERE dueDate = ? AND isCompleted = 1',
      [todayDate],
    )) ?? 0;

    return {'total': total, 'completed': completed};
  }

  Future<Set<String>> getDatesWithTasks(String monthPrefix) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT dueDate FROM tasks WHERE dueDate LIKE ?',
      ['$monthPrefix%'],
    );
    return result.map((e) => e['dueDate'] as String).toSet();
  }

  // ================= NOTES OPERATIONS =================

  Future<int> insertNote(NoteModel note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> updateNote(NoteModel note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<NoteModel>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((json) => NoteModel.fromMap(json)).toList();
  }

  Future<List<NoteModel>> getNotesByDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'updatedAt DESC',
    );
    return result.map((json) => NoteModel.fromMap(json)).toList();
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    final db = await instance.database;
    final lower = '%$query%';
    final result = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ? OR tags LIKE ?',
      whereArgs: [lower, lower, lower],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((json) => NoteModel.fromMap(json)).toList();
  }

  Future<Set<String>> getDatesWithNotes(String monthPrefix) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT date FROM notes WHERE date LIKE ?',
      ['$monthPrefix%'],
    );
    return result.map((e) => e['date'] as String).toSet();
  }

  // ================= STORAGE / PRIVACY UTILITIES =================

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await instance.database;
    final tasksCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tasks'),
    ) ?? 0;
    final notesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM notes'),
    ) ?? 0;
    return {'tasks': tasksCount, 'notes': notesCount};
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('tasks');
    await db.delete('notes');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
