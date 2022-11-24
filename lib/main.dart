import 'dart:async';
//import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
//import 'package:sqflite/sqflite.dart';


import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

// SQLiteを使用する際は、下記のパッケージをimportして下さい。
// sqflite:
//  path:

class Dog {
  final int id;
  final String location;
  final String rack;
  final String board;
  final String contaner;
  final String part;

  Dog(
      {required this.id,
      required this.location,
      required this.rack,
      required this.board,
      required this.contaner,
      required this.part});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'Location': location,
      'Rack': rack,
      'Board': board,
      'Contaner': contaner,
      'Part': part,
    };
  }

  //printで見やすくするための実装
  @override
  String toString() {
    return 'Dog{id: $id, Location: $location, Rack: $rack, Board: $board, Contaner: $contaner, Part:$part}';
  }
} //DogClass

void main() async {
  print('Using sqlite3 ${sqlite3.version}');

  // Create a new in-memory database. To use a database backed by a file, you
  // can replace this with sqlite3.open(yourFilePath).
  final database = sqlite3.openInMemory();

  // Create a table and insert some data
  database.execute('''
    CREATE TABLE artists (
      id INTEGER NOT NULL PRIMARY KEY,
      name TEXT NOT NULL
    );
  ''');

  // Prepare a statement to run it multiple times:
  final stmt = database.prepare('INSERT INTO artists (name) VALUES (?)');
  stmt
    ..execute(['The Beatles'])
    ..execute(['Led Zeppelin'])
    ..execute(['The Who'])
    ..execute(['Nirvana']);

  // Dispose a statement when you don't need it anymore to clean up resources.
  stmt.dispose();

  // You can run select statements with PreparedStatement.select, or directly
  // on the database:
  final ResultSet resultSet =
      database.select('SELECT * FROM artists WHERE name LIKE ?', ['The %']);

  // You can iterate on the result set in multiple ways to retrieve Row objects
  // one by one.
  for (final Row row in resultSet) {
    print('Artist[id: ${row['id']}, name: ${row['name']}]');
  }

  // Register a custom function we can invoke from sql:
  database.createFunction(
    functionName: 'dart_version',
    argumentCount: const AllowedArgumentCount(0),
    function: (args) => Platform.version,
  );
  print(database.select('SELECT dart_version()'));

  // Don't forget to dispose the database to avoid memory leaks
  database.dispose();










  // このソースコードはWidgetで視覚化しておらず、結果は全てコンソール上に出力しています。
  // 出力結果は最後に表示させます。
 
  /*
  ////WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    // pathをデータベースに設定しています。
    // 'path'パッケージからの'join'関数を使用する事は、DBをお互い（iOS, Android）のプラットフォームに構築し、
    // pathを確保するのに良い方法です。
    join(await getDatabasesPath(), 'doggie_database2.db'),

    // dogs テーブルのデータベースを作成しています。
    // ここではSQLの解説は省きます。
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE dogs(id INTEGER PRIMARY KEY AUTOINCREMENT, Location TEXT, Rack TEXT, Board TEXT, Contaner TEXT, Part TEXT )",
      );
    },
    // version 1のSQLiteを使用します。
    version: 1,
  );
  */

  
  // dogsテーブルのデータを全件取得する
  Future<List<Dog>> dogs() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dogs');
    return List.generate(maps.length, (i) {
      return Dog(
        id: maps[i]['id'],
        location: maps[i]['Location'],
        rack: maps[i]['Rack'],
        board: maps[i]['Board'],
        contaner: maps[i]['Contaner'],
        part: maps[i]['Part'],
      );
    });
  }

  // DBからデータを一件だけ取得するための関数
  Future<List<Map<String, dynamic>>> selectDogs(int id) async {
    final db = await database;
    return await db.query(
      'memo',
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );
  }

  // DBにデータを挿入するための関数です。
  Future<void> insertDog(Dog dog) async {
    // データベースのリファレンスを取得します。
    final Database db = await database;
    // テーブルにDogのデータを入れます。
    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

 

  void search() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dogs');

    //条件の指定の例。
    //final id = 1;
    //print(await db.query('dogs', where: 'id = ?', whereArgs: [id]));

    //LIKE句を使いたい場合は以下のように書くことができます。
    //このように書くことで「Flutter」から始まるtextにマッチします。
    final code = '002';
    final Results =
        await db.query('dogs', where: 'board LIKE ?', whereArgs: ['${code}%']);

    if (Results.isEmpty) {
      print('empty');
      return;
    }

    // ここから検索処理
    String json = Results.toString();
    RegExp searchstring = RegExp(r'Location:.....');

    List<String?> searchresuit =
        searchstring.allMatches(json).map((match) => match.group(0)).toList();
    
    print('既に$searchresuitに登録されています。');

    print(Results);

    //IN句を使いたい場合は以下のように書くことができます。
    //final ids = [1, 2];
    //print(await db.query('dogs', where: 'id IN (${ids.join(', ')})'));
  }




  // DB内にあるデータを更新するための関数
  Future<void> updateDog(Dog dog) async {
    final db = await database;

    await db.update(
      'dogs',
      dog.toMap(),
      where: "id = ?",
      whereArgs: [dog.id],
    );
  }

  // DBからデータを削除するための関数
  Future<void> deleteDog(int id) async {
    // Get a reference to the database.
    final db = await database;

    // データベースからdogのデータを削除する。
    // 今回は使用していない。
    await db.delete(
      'dogs',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // 具体的なデータ
  var fido = Dog(
    id: 0,
    location: 'Fido',
    board: '001',
    rack: '35',
    contaner: '1',
    part: '1',
  );

  var bobo = Dog(
    id: 1,
    location: 'Bobo',
    board: '002',
    rack: '17',
    contaner: '2',
    part: '2',
  );

  // データベースにDogのデータを挿入
  await insertDog(fido);
  await insertDog(bobo);

  print(await dogs());

  fido = Dog(
    id: fido.id,
    location: fido.location,
    board: '',
    rack: fido.rack + '7',
    contaner: '',
    part: '',
  );
  // データベース内のfidoを更新
  //await updateDog(fido);

  // fidoのアップデートを表示
  //print("updated DB");
  //print(await dogs());
  search();
}
