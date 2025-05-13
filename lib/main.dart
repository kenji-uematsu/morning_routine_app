import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// 必要なimportを追加
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

// 共通のテキストスタイルを定義
final TextStyle commonTextStyle = const TextStyle(
  fontSize: 14.0,
  letterSpacing: 0.0,
  height: 1.2,
  fontWeight: FontWeight.normal,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 多言語対応の設定
      localizationsDelegates: const [
        AppLocalizations.delegate, // 自動生成されるクラス
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // 英語
        Locale('ja', ''), // 日本語
      ],
      debugShowCheckedModeBanner: false,
      title: 'Task Cycle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const MyHomePage(title: 'Task Cycle'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  // タスクリストを追加
  final List<Task> _tasks = [];

  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    // アプリのライフサイクル監視を開始
    WidgetsBinding.instance.addObserver(this);

    // 初回起動チェックを追加
    _checkFirstLaunch();

    // 起動時に一度チェック
    _loadTasks().then((_) {
      _checkAndResetTasks();
    });
    // 定期的な確認タイマーを開始（1分ごと）
    _startCheckTimer();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startCheckTimer() {
    // 1分ごとにチェック
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndResetTasks();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // バックグラウンドから復帰時にもチェック
    if (state == AppLifecycleState.resumed) {
      _checkAndResetTasks();
    }
  }

  // タスクのリセットが必要かチェックし、必要ならリセットする関数
  Future<void> _checkAndResetTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String lastResetDateStr = prefs.getString('last_reset_date') ?? '';
    final DateTime lastResetDate =
        lastResetDateStr.isEmpty
            ? DateTime(2000) // デフォルト値として過去の日付
            : DateTime.parse(lastResetDateStr);
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // 日付が変わった場合
    if (lastResetDateStr != today) {
      _resetDailyTasks();

      // 毎週のタスクは月曜日にリセット
      if (now.weekday == DateTime.monday) {
        _resetWeeklyTasks();
      }

      // 毎月のタスクは1日にリセット
      if (now.day == 1) {
        _resetMonthlyTasks();
      }

      // 通常のリセット日を更新
      await prefs.setString('last_reset_date', today);
    }
  }

  // 毎日のタスクをリセットする関数
  void _resetDailyTasks() {
    setState(() {
      for (var task in _tasks) {
        if (task.period == TaskPeriod.daily) {
          task.isCompleted = false;
        }
      }
    });
  }

  // 毎週のタスクをリセットする関数
  void _resetWeeklyTasks() {
    setState(() {
      for (var task in _tasks) {
        if (task.period == TaskPeriod.weekly) {
          task.isCompleted = false;
        }
      }
    });
  }

  // 毎月のタスクをリセットする関数
  void _resetMonthlyTasks() {
    setState(() {
      for (var task in _tasks) {
        if (task.period == TaskPeriod.monthly) {
          task.isCompleted = false;
        }
      }
    });
  }

  // タスクの完了状態を切り替える関数
  void _toggleTaskCompletion(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  // タスクリストを更新する関数（永続化含む）
  Future<void> _updateTasks(List<Task> newTasks) async {
    setState(() {
      _tasks.clear();
      _tasks.addAll(newTasks);
    });

    // タスクの状態を保存
    await _saveTasks();
  }

  // タスクをSharedPreferencesに保存
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskData =
        _tasks.map((task) {
          return '${task.title}|${task.isCompleted}|${task.period?.index ?? 0}';
        }).toList();

    await prefs.setStringList('tasks', taskData);
  }

  // アプリ起動時にタスクを読み込む
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskData = prefs.getStringList('tasks');

    if (taskData != null && taskData.isNotEmpty) {
      setState(() {
        _tasks.clear();
        for (String data in taskData) {
          final parts = data.split('|');
          if (parts.length >= 3) {
            final title = parts[0];
            final isCompleted = parts[1] == 'true';
            final periodIndex = int.tryParse(parts[2]) ?? 0;
            final period = TaskPeriod.values[periodIndex];

            _tasks.add(Task(title, isCompleted: isCompleted, period: period));
          }
        }
      });
    }
  }

  // 設定ページへ移動
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                SettingsPage(tasks: _tasks, onTasksChanged: _updateTasks),
      ),
    );
  }

  // アプリの説明ダイアログを表示する関数
  void _showAppExplanationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.aboutAppTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.mainFeaturesHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.mainFeaturesDescription,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),

                Text(
                  AppLocalizations.of(context)!.autoResetHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.autoResetDescription,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),

                Text(
                  AppLocalizations.of(context)!.taskManagementHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.taskManagementDescription,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.okButton),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  // 初回起動時のチェック
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (isFirstLaunch) {
      // UIが構築された後にダイアログを表示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAppExplanationDialog(); // メソッド名を変更
      });
      // 初回フラグを更新
      await prefs.setBool('first_launch', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 期間ごとにタスクをグループ化
    final dailyTasks =
        _tasks.where((task) => task.period == TaskPeriod.daily).toList();
    final weeklyTasks =
        _tasks.where((task) => task.period == TaskPeriod.weekly).toList();
    final monthlyTasks =
        _tasks.where((task) => task.period == TaskPeriod.monthly).toList();

    final isAllEmpty =
        dailyTasks.isEmpty && weeklyTasks.isEmpty && monthlyTasks.isEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          AppLocalizations.of(context)!.homeScreenTitle, // appTitleから変更
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        toolbarHeight: 44.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: _openSettings,
          ),
        ],
      ),
      body:
          isAllEmpty
              ? Align(
                alignment: const Alignment(0, -0.5), // 画面中央よりやや上
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    AppLocalizations.of(context)!.noTaskMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800], // 指定通り
                    ),
                  ),
                ),
              )
              : ListView(
                children: [
                  if (dailyTasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.dailyTask,
                    ),
                    ...dailyTasks.map((task) => _buildTaskItem(task)),
                  ],
                  if (weeklyTasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.weeklyTask,
                    ),
                    ...weeklyTasks.map((task) => _buildTaskItem(task)),
                  ],
                  if (monthlyTasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.monthlyTask,
                    ),
                    ...monthlyTasks.map((task) => _buildTaskItem(task)),
                  ],
                ],
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      color: Colors.grey[100],
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Opacity(
      // チェック済みのタスクは半透明表示
      opacity: task.isCompleted ? 0.6 : 1.0,
      child: ListTile(
        title: Text(
          task.title,
          style: TextStyle(
            // decoration: task.isCompleted ? TextDecoration.lineThrough : null, // 取り消し線を削除
            color: task.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        leading: Checkbox(
          value: task.isCompleted,
          // チェック済みの場合は操作不能に
          onChanged:
              task.isCompleted
                  ? null // nullにすることでチェックボックスが無効化される
                  : (_) => _toggleTaskCompletion(_tasks.indexOf(task)),
        ),
        // タップ操作も無効化
        onTap:
            task.isCompleted
                ? null
                : () {
                  setState(() {
                    _toggleTaskCompletion(_tasks.indexOf(task));
                  });
                },
      ),
    );
  }
}

enum TaskPeriod { daily, weekly, monthly }

class Task {
  String title;
  bool isCompleted;
  TaskPeriod? period; // nullを許容するよう?マークを追加

  Task(this.title, {this.isCompleted = false, this.period = TaskPeriod.daily});
}

// 設定ページ
class SettingsPage extends StatefulWidget {
  final List<Task> tasks;
  final Function(List<Task>) onTasksChanged;

  const SettingsPage({
    super.key,
    required this.tasks,
    required this.onTasksChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<Task> _editableTasks;
  int? _editingIndex; // 編集中のインデックスを追加

  @override
  void initState() {
    super.initState();
    // タスクのコピーを作成して編集可能にする
    _editableTasks =
        widget.tasks.map((task) {
          // nullチェックを追加
          final TaskPeriod safePeriod = task.period ?? TaskPeriod.daily;
          return Task(
            task.title,
            isCompleted: task.isCompleted,
            period: safePeriod, // nullの場合はdailyをデフォルト値として使用
          );
        }).toList();
  }

  // 新しいタスクを追加
  void _addTask() {
    setState(() {
      // 空のタスクを追加して即座に編集モードに
      _editableTasks.add(Task(''));
      _editingIndex = _editableTasks.length - 1;
    });
  }

  // タスクを削除
  void _deleteTask(int index) {
    setState(() {
      _editableTasks.removeAt(index);
      _editingIndex = null; // 編集モードをクリア
    });
  }

  void _showAppExplanationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.aboutAppTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.mainFeaturesHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.mainFeaturesDescription,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),

                Text(
                  AppLocalizations.of(context)!.autoResetHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.autoResetDescription,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),

                Text(
                  AppLocalizations.of(context)!.taskManagementHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.taskManagementDescription,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.okButton),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 期間ごとにタスクをグループ化
    final dailyTasks =
        _editableTasks
            .where(
              (task) => task.period == TaskPeriod.daily || task.period == null,
            )
            .toList();
    final weeklyTasks =
        _editableTasks
            .where((task) => task.period == TaskPeriod.weekly)
            .toList();
    final monthlyTasks =
        _editableTasks
            .where((task) => task.period == TaskPeriod.monthly)
            .toList();

    return GestureDetector(
      onTap: () {
        if (_editingIndex != null) {
          setState(() {
            _editingIndex = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(
            AppLocalizations.of(context)!.settingsScreenTitle, // settingsから変更
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          toolbarHeight: 44.0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black), // 色を追加
            onPressed: () {
              _editableTasks.removeWhere((task) => task.title.isEmpty);
              widget.onTasksChanged(_editableTasks);
              Navigator.pop(context);
            },
          ),
          actions: [
            // 情報アイコンを追加
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.black),
              tooltip: AppLocalizations.of(context)!.howToUse,
              onPressed: _showAppExplanationDialog, // 直接クラス内のメソッドを呼び出す
            ),
          ],
        ),
        body: ListView(
          children: [
            // 毎日のタスクセクション
            _buildSectionHeader(
              AppLocalizations.of(context)!.dailyTask,
              () => _addTaskWithPeriod(TaskPeriod.daily),
            ),
            ...dailyTasks.asMap().entries.map(
              (entry) => _buildTaskItem(
                entry.value,
                _editableTasks.indexOf(entry.value),
              ),
            ),
            const Divider(height: 1.0, thickness: 0.5),

            // 毎週のタスクセクション
            _buildSectionHeader(
              AppLocalizations.of(context)!.weeklyTask,
              () => _addTaskWithPeriod(TaskPeriod.weekly),
            ),
            ...weeklyTasks.asMap().entries.map(
              (entry) => _buildTaskItem(
                entry.value,
                _editableTasks.indexOf(entry.value),
              ),
            ),
            const Divider(height: 1.0, thickness: 0.5),

            // 毎月のタスクセクション
            _buildSectionHeader(
              AppLocalizations.of(context)!.monthlyTask,
              () => _addTaskWithPeriod(TaskPeriod.monthly),
            ),
            ...monthlyTasks.asMap().entries.map(
              (entry) => _buildTaskItem(
                entry.value,
                _editableTasks.indexOf(entry.value),
              ),
            ),
          ],
        ),
        // メインの+ボタンは削除してもOK（セクションごとに+ボタンがあるため）
      ),
    );
  }

  // セクションヘッダーを作成するヘルパーメソッド
  Widget _buildSectionHeader(String title, VoidCallback onAddPressed) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          // プラスボタン
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.black,
            ), // teal → black に変更
            splashRadius: 20,
            onPressed: onAddPressed,
          ),
        ],
      ),
    );
  }

  // 指定した期間のタスクを追加
  void _addTaskWithPeriod(TaskPeriod period) {
    setState(() {
      // 新しいタスクを指定の期間で作成
      final newTask = Task('', period: period);
      _editableTasks.add(newTask);
      _editingIndex = _editableTasks.length - 1;
    });
  }

  // タスクアイテムを作成するヘルパーメソッド
  Widget _buildTaskItem(Task task, int index) {
    final isEditing = _editingIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _editingIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        height: 50.0,
        child: Row(
          children: [
            // チェックボックスを追加
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                setState(() {
                  task.isCompleted = value ?? false;
                });
              },
            ),
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                height: 30.0,
                child:
                    isEditing
                        ? TextField(
                          autofocus: true,
                          controller: TextEditingController(text: task.title),
                          style: commonTextStyle,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            // テキスト変更時にリアルタイムでタイトルを更新
                            task.title = value;
                          },
                          onSubmitted: (value) {
                            setState(() {
                              _editingIndex = null;
                            });
                          },
                        )
                        : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            task.title.isEmpty
                                ? AppLocalizations.of(context)!.inputTaskName
                                : task.title, // '(タスク名を入力)'から変更
                            style: TextStyle(
                              // decoration: task.isCompleted ? TextDecoration.lineThrough : null, // 取り消し線を削除
                              color:
                                  task.isCompleted ? Colors.grey : Colors.black,
                            ).merge(commonTextStyle),
                          ),
                        ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              splashRadius: 20,
              onPressed: () => _deleteTask(index),
            ),
          ],
        ),
      ),
    );
  }
}
