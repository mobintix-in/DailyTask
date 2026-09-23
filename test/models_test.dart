import 'package:flutter_test/flutter_test.dart';
import 'package:dailytask/models/task_model.dart';
import 'package:dailytask/models/note_model.dart';

void main() {
  group('TaskModel Tests', () {
    test('TaskModel serializes to and from Map correctly', () {
      final task = TaskModel(
        id: 1,
        title: 'Complete Project',
        description: 'Test description',
        dueDate: '2026-09-23',
        dueTime: '10:00',
        priority: 'high',
        category: 'Work',
        isCompleted: false,
        reminderDateTime: '2026-09-23T10:00:00',
        notificationId: 101,
      );

      final map = task.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Complete Project');
      expect(map['priority'], 'high');
      expect(map['isCompleted'], 0);

      final fromMap = TaskModel.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.title, 'Complete Project');
      expect(fromMap.priority, 'high');
      expect(fromMap.isCompleted, false);
      expect(fromMap.reminderDateTime, '2026-09-23T10:00:00');
    });

    test('TaskModel copyWith works properly', () {
      final task = TaskModel(
        id: 1,
        title: 'Original Title',
        dueDate: '2026-09-23',
        priority: 'medium',
      );

      final updated = task.copyWith(isCompleted: true, priority: 'high');
      expect(updated.id, 1);
      expect(updated.title, 'Original Title');
      expect(updated.isCompleted, true);
      expect(updated.priority, 'high');
    });
  });

  group('NoteModel Tests', () {
    test('NoteModel serializes to and from Map correctly', () {
      final note = NoteModel(
        id: 42,
        title: 'Private Journal',
        content: 'Offline thoughts and ideas',
        date: '2026-09-23',
        colorHex: '#00C896',
        tags: 'Journal, Personal',
        isPinned: true,
        updatedAt: '2026-09-23T12:00:00',
      );

      final map = note.toMap();
      expect(map['id'], 42);
      expect(map['title'], 'Private Journal');
      expect(map['isPinned'], 1);
      expect(map['colorHex'], '#00C896');

      final fromMap = NoteModel.fromMap(map);
      expect(fromMap.id, 42);
      expect(fromMap.title, 'Private Journal');
      expect(fromMap.isPinned, true);
      expect(fromMap.tags, 'Journal, Personal');
    });
  });
}
