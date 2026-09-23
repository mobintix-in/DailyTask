# DailyTask 📅✍️

A sleek, privacy-focused, and 100% offline daily task and note-taking application built with **Flutter**. Designed with an Apple-inspired aesthetic for a fast, distraction-free productivity experience.

---

## ✨ Features

### 📋 Task Management
- **Smart Organization**: Categorize tasks by Work, Personal, Study, Health, Finance, and more.
- **Priority Levels**: Flag tasks as Urgent, High, Medium, or Low with intuitive color indicators.
- **Subtasks & Checklists**: Break down complex tasks into bite-sized actionable steps.
- **Due Dates & Times**: Schedule tasks with precise deadlines.
- **Quick Filters & Search**: Effortlessly filter by *All*, *Today*, *Upcoming*, and *Completed*, or use instant keyword search.

### 🗓️ Interactive Calendar
- **Monthly Overview**: Visual calendar grid highlighting days with scheduled tasks and notes.
- **Daily Timeline**: Tap any date to view scheduled items and tasks for that specific day.
- **Jump to Today**: Instantly navigate back to the current date with a single tap.

### 📝 Apple-Style Notes
- **Distraction-Free Editor**: Clean, focused interface for capturing thoughts and ideas quickly.
- **Color Coding**: Categorize notes visually using curated pastel color swatches.
- **Pinning**: Pin critical notes to keep them pinned to the top of your workspace.
- **Swipe Actions**: Swipe to delete with an instant Undo option.

### 🔔 Offline Local Notifications
- **Timely Reminders**: Get notified right on time for your scheduled tasks.
- **Custom Alert Sounds**: Built-in chime, bell, and alarm audio cues.
- **100% Offline**: All notifications are scheduled on-device using local timezone triggers—no external servers needed.

### 🔒 Privacy & Security First
- **PIN App Lock**: Protect your private tasks and notes with a secure 4-digit PIN (hashed with SHA-256).
- **100% Local Storage**: Everything is stored in an encrypted/local SQLite database on your device.
- **Zero Cloud & Zero Tracking**: No accounts, no internet required, no analytics, and zero data leaves your phone.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK ^3.9.2)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite) (Offline SQLite engine)
- **Scheduling & Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) & [timezone](https://pub.dev/packages/timezone)
- **Local Security**: [shared_preferences](https://pub.dev/packages/shared_preferences) & [crypto](https://pub.dev/packages/crypto) (SHA-256 hashing)
- **Formatting**: [intl](https://pub.dev/packages/intl)
- **Icons**: [cupertino_icons](https://pub.dev/packages/cupertino_icons) & Material Symbols

---

## 📂 Project Structure

```text
lib/
├── main.dart                  # App entry point, initialization & root navigation
├── models/
│   ├── task_model.dart        # Task & Subtask data models and SQLite mapping
│   └── note_model.dart        # Note data model and SQLite serialization
├── screens/
│   ├── tasks_screen.dart      # Task lists, filters, search & creation modal
│   ├── calendar_screen.dart   # Interactive calendar month grid & daily view
│   ├── notes_screen.dart      # Notes list, card grid & note editor screen
│   ├── privacy_screen.dart    # Security settings, PIN management & data options
│   └── pin_lock_screen.dart   # Security PIN entry & setup screen
├── services/
│   ├── database_service.dart  # SQLite database helper (CRUD operations)
│   ├── notification_service.dart # Local notification scheduler & channels
│   └── security_service.dart  # PIN management & SHA-256 hashing service
├── theme/
│   └── app_theme.dart         # Design system tokens, typography, and palettes
└── widgets/
    └── app_toast.dart         # Custom floating action toasts & notifications
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24.0 or higher recommended)
- Android Studio / VS Code with Flutter extension
- An Android device or emulator (API level 21+)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/mobintix-in/DailyTask.git
   cd DailyTask
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on connected device/emulator:**
   ```bash
   flutter run
   ```

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
