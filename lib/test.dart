import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SQLite Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  Database? _database;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'todo_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT)',
        );
      },
      version: 1,
    );
    _refreshTasks();
  }

  Future<void> _refreshTasks() async {
    final List<Map<String, dynamic>> tasks = await _database!.query('tasks');
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _addTask(String title) async {
    await _database!.insert(
      'tasks',
      {'title': title},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _refreshTasks();
  }

  Future<void> _deleteTask(int id) async {
    await _database!.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    _refreshTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter SQLite Demo')),
      body: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'New Task'),
          ),
          ElevatedButton(
            onPressed: () {
              _addTask(_controller.text);
              _controller.clear();
            },
            child: Text('Add Task'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_tasks[index]['title']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteTask(_tasks[index]['id']);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
