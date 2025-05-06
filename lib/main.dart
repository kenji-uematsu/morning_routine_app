import 'package:flutter/material.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
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
      home: const MyHomePage(title: 'Morning Routine'),
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

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // タスクリストを追加
  final List<Task> _tasks = [
    Task('歯を磨く'),
    Task('顔を洗う'),
    Task('朝食を食べる'),
    Task('準備をする'),
  ];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // タスクの完了状態を切り替える関数
  void _toggleTaskCompletion(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  // タスクリストを更新する関数
  void _updateTasks(List<Task> newTasks) {
    setState(() {
      _tasks.clear();
      _tasks.addAll(newTasks);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // カウンター部分（既存のまま）
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('You have pushed the button this many times:'),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),

          // タスクリスト（新規追加）
          const SizedBox(height: 20),
          const Text(
            '朝のルーティン',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _tasks[index].title,
                    style: TextStyle(
                      decoration:
                          _tasks[index].isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                    ),
                  ),
                  leading: Checkbox(
                    value: _tasks[index].isCompleted,
                    onChanged: (_) => _toggleTaskCompletion(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Task {
  String title;
  bool isCompleted;

  Task(this.title, {this.isCompleted = false});
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
        widget.tasks
            .map((task) => Task(task.title, isCompleted: task.isCompleted))
            .toList();
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 空のタスクを削除
            _editableTasks.removeWhere((task) => task.title.isEmpty);
            // 変更をメイン画面に反映
            widget.onTasksChanged(_editableTasks);
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: _editableTasks.length,
        itemBuilder: (context, index) {
          final isEditing = _editingIndex == index;

          // ListTileの代わりにGestureDetector+Containerの組み合わせを使用
          return GestureDetector(
            onTap: () {
              setState(() {
                _editingIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              height: 50.0, // 固定高さを設定
              child: Row(
                children: [
                  // タイトル部分（メインコンテンツ）
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft, // 左寄せの中央揃え
                      height: 30.0, // 固定高さを設定（親コンテナより小さく）
                      child:
                          isEditing
                              // 編集モードの場合
                              ? TextField(
                                autofocus: true,
                                controller: TextEditingController(
                                  text: _editableTasks[index].title,
                                ),
                                style: commonTextStyle,
                                decoration: const InputDecoration(
                                  isCollapsed: true, // これを追加！高さの制御が良くなります
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (value) {
                                  setState(() {
                                    if (value.isNotEmpty) {
                                      _editableTasks[index].title = value;
                                    }
                                    _editingIndex = null;
                                  });
                                },
                              )
                              // 表示モードの場合
                              : Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _editableTasks[index].title.isEmpty
                                      ? '(タスク名を入力)'
                                      : _editableTasks[index].title,
                                  style: commonTextStyle,
                                ),
                              ),
                    ),
                  ),

                  // 削除ボタン
                  IconButton(
                    icon: const Icon(Icons.delete),
                    splashRadius: 20,
                    onPressed: () => _deleteTask(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'タスクを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
