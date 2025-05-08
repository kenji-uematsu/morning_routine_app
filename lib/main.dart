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

  // This widget is the root of your application.
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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const MyHomePage(title: 'Task Cycle'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  // デバッグモードを制御するフラグ
  static const bool _debugModeEnabled = false; // falseに設定するとデバッグ機能が無効になる

  // タスクリストを追加
  final List<Task> _tasks = [
    Task('歯を磨く', period: TaskPeriod.daily),
    Task('顔を洗う', period: TaskPeriod.daily),
    Task('朝食を食べる', period: TaskPeriod.daily),
    Task('準備をする', period: TaskPeriod.daily),
    // 追加でweeklyやmonthlyのタスクがあれば、それらも明示的に期間を指定
  ];

  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    // アプリのライフサイクル監視を開始
    WidgetsBinding.instance.addObserver(this);
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
    final lastResetDate = prefs.getString('last_reset_date') ?? '';
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // デバッグ用: 特定の時刻（例：毎時xx分）でリセットさせる
    final bool debugTimeReset =
        _debugModeEnabled && now.minute == 3; // 例：毎時30分にリセット

    // 日付が変わった場合またはデバッグトリガーが発動した場合
    if (lastResetDate != today || debugTimeReset) {
      print("Resetting tasks! Debug trigger: $debugTimeReset");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All tasks reset for debugging')),
      );

      // 毎日のタスクは毎日リセット
      _resetDailyTasks();

      // 毎週のタスクは月曜日にリセット (デバッグ中は常にリセットも可能)
      if (now.weekday == DateTime.monday || debugTimeReset) {
        _resetWeeklyTasks();
      }

      // 毎月のタスクは1日にリセット (デバッグ中は常にリセットも可能)
      if (now.day == 1 || debugTimeReset) {
        _resetMonthlyTasks();
      }

      // デバッグトリガーの場合は特別なキーを使用
      if (debugTimeReset) {
        await prefs.setString(
          'debug_last_reset',
          DateFormat('yyyy-MM-dd HH:mm').format(now),
        );
      } else {
        // 通常のリセット日を更新
        await prefs.setString('last_reset_date', today);
      }
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

  // 強制的にタスクをリセットする関数
  void _forceResetTasks() {
    _resetDailyTasks();
    _resetWeeklyTasks();
    _resetMonthlyTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All tasks reset for debugging')),
    );
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold, // 太字設定を追加
          ),
        ),
        toolbarHeight: 44.0, // 高さを44に設定
        actions: [
          // デバッグ用リセットボタン
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Debug Reset',
            onPressed: () {
              _forceResetTasks(); // 強制的にリセット
            },
          ),
          // 既存の設定ボタン
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          // 毎日のタスクセクション
          if (dailyTasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader(AppLocalizations.of(context)!.dailyTask),
            ...dailyTasks.map((task) => _buildTaskItem(task)),
          ],

          // 毎週のタスクセクション
          if (weeklyTasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader(AppLocalizations.of(context)!.weeklyTask),
            ...weeklyTasks.map((task) => _buildTaskItem(task)),
          ],

          // 毎月のタスクセクション
          if (monthlyTasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader(AppLocalizations.of(context)!.monthlyTask),
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
            AppLocalizations.of(context)!.settings,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          toolbarHeight: 44.0, // 高さを44に設定
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _editableTasks.removeWhere((task) => task.title.isEmpty);
              widget.onTasksChanged(_editableTasks);
              Navigator.pop(context);
            },
          ),
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
            icon: const Icon(Icons.add, color: Colors.teal),
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
