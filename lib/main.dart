import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => InputScreen(),
        '/second': (context) => SecondScreen(),
        '/nicknameList': (context) => NicknameListScreen(),
      },
    );
  }
}

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isButtonEnabled = false;
  String _pat = "";

  void _checkInputValidity(String input) {
    setState(() {
      _isButtonEnabled = RegExp(r'^[a-zA-Z0-9]{3,20}$').hasMatch(input);
    });
  }

  void _saveNickname(BuildContext context) async {
    String nickname = _nicknameController.text;
    bool exists = await _checkNicknameExistence(nickname);
    if (!exists) {
      await _saveToDatabase(nickname);
      Navigator.pushNamed(context, '/second');
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Erro'),
            content:
                Text('O apelido já está em uso. Por favor, escolha outro.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _saveToDatabase(String nickname) async {
    final database = openDatabase(
      join(await getDatabasesPath(), 'nicknames_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE nicknames(id INTEGER PRIMARY KEY, nickname TEXT)",
        );
      },
      version: 1,
    );

    final Database db = await database;
    await db.insert(
      'nicknames',
      {'nickname': nickname},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Apelido salvo no banco de dados: $nickname');
  }

  Future<bool> _checkNicknameExistence(String nickname) async {
    final database = openDatabase(
      join(await getDatabasesPath(), 'nicknames_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE nicknames(id INTEGER PRIMARY KEY, nickname TEXT)",
        );
      },
      version: 1,
    );

    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'nicknames',
      where: 'nickname = ?',
      whereArgs: [nickname],
    );

    return result.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Input Screen'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PAT: $_pat',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nicknameController,
                onChanged: _checkInputValidity,
                decoration: InputDecoration(
                  labelText: 'Apelido',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _isButtonEnabled ? () => _saveNickname(context) : null,
                child: Text('Salvar'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/nicknameList');
                },
                child: Text('Ir para Lista de Apelidos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  List<String> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    final response =
        await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _posts = data.map((post) => post['title'].toString()).toList();
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Screen'),
      ),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_posts[index]),
          );
        },
      ),
    );
  }
}

class NicknameListScreen extends StatefulWidget {
  @override
  _NicknameListScreenState createState() => _NicknameListScreenState();
}

class _NicknameListScreenState extends State<NicknameListScreen> {
  List<String> _nicknames = [];

  @override
  void initState() {
    super.initState();
    _fetchNicknames();
  }

  Future<void> _fetchNicknames() async {
    final database = openDatabase(
      join(await getDatabasesPath(), 'nicknames_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE nicknames(id INTEGER PRIMARY KEY, nickname TEXT)",
        );
      },
      version: 1,
    );

    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query('nicknames');
    setState(() {
      _nicknames = result.map((item) => item['nickname'] as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Apelidos'),
      ),
      body: ListView.builder(
        itemCount: _nicknames.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_nicknames[index]),
          );
        },
      ),
    );
  }
}
