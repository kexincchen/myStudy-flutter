import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
import 'package:home_widget/home_widget.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

const String appGroupId = 'group.aiwidget';
const String iOSWidgetName = 'AI-widget';

void main() async {
  // await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Generator App',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final TextEditingController promptController;
  int selectedNumber = 1;
  List<String> generatedTexts = [];
  late bool isLoading;

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId(appGroupId);
    promptController = TextEditingController();
    isLoading = false;
    loadResponsesFromDatabase();
  }

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  Future<List<String>> getGptResponses(String inputText) async {
    // final String apiUrl = 'https://api.openai.com/v1/completions';
    // final response = await http.post(
    //   Uri.parse(apiUrl),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${dotenv.env['OPEN_AI_API_KEY']}',
    //   },
    //   body: jsonEncode(
    //     {
    //       "model": "gpt-3.5-turbo-instruct",
    //       "prompt": inputText,
    //       "max_tokens": 250,
    //       "temperature": 0.8,
    //     },
    //   ),
    // );

    // final data = json.decode(response.body);
    List<String> responses = ["1. English-French", "2. Chinese-Cantonese"];

    responses = responses
        .where((response) => response.trim().isNotEmpty)
        .map((response) => response.replaceFirst(RegExp(r'^\d+\.\s*'), ''))
        .toList();

    for (String response in responses) {
      await DatabaseHelper.instance.insert({
        DatabaseHelper.columnResponse: response,
      });
    }

    updateWidget(responses[0]);
    return responses;
  }

  Future<void> loadResponsesFromDatabase() async {
    List<Map<String, dynamic>> queryRows =
        await DatabaseHelper.instance.queryAllRows();
    setState(() {
      generatedTexts = queryRows
          .map((row) => row[DatabaseHelper.columnResponse] as String)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Widget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<int>(
              value: selectedNumber,
              items: [1, 2, 3, 4, 5].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('Number $value'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedNumber = newValue!;
                });
              },
            ),
            TextField(
              controller: promptController,
              decoration: InputDecoration(
                hintText: 'Caption...',
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() {
                        isLoading = true;
                      });

                      String inputText = promptController.text;
                      List<String> responses = await getGptResponses(
                          'Give me $selectedNumber $inputText ');

                      setState(() {
                        generatedTexts.addAll(responses);
                        isLoading = false;
                      });
                    },
              child: Text('Generate'),
            ),
            SizedBox(height: screenHeight * 0.02),
            isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: generatedTexts.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text('${index + 1}.',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  child: Text(generatedTexts[index]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

void updateWidget(String response) {
  HomeWidget.saveWidgetData<String>('headline_description', response);
  HomeWidget.updateWidget(
    iOSName: iOSWidgetName,
  );
}

class DatabaseHelper {
  static final _databaseName = "MyDatabase.db";
  static final _databaseVersion = 1;
  static final table = 'responses';
  static final columnId = 'id';
  static final columnResponse = 'response';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnResponse TEXT NOT NULL
          )
          ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }
}
