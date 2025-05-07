# Task Cycle App

A simple Flutter app for managing recurring tasks. Efficiently track and manage your daily, weekly, and monthly habits and routines.

## Features

- Periodic Task Management: Organize tasks by daily, weekly, and monthly cycles
- Automatic Reset: Tasks automatically reset (uncheck) based on their period
- Daily tasks: Reset at midnight every day
- Weekly tasks: Reset at midnight every Monday
- Monthly tasks: Reset at midnight on the first day of each month
- Intuitive Interface: Simple UI for adding, editing, and deleting tasks
- Multilingual Support: Available in English and Japanese (automatically adapts to device language settings)

## Implementation

- Flutter framework for cross-platform deployment (iOS & Android)
- Provider pattern for state management
- SQLite database for local storage
- Custom UI components for a seamless user experience
- Notification API for reminders

## Getting Started

This project is built with Flutter. To run this project:

```bash
flutter pub get
flutter run
```

### Flutter Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)
