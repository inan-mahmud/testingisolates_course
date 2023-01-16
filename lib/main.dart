import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testingisolates_course/models/todo/todo.dart';

import 'dart:developer' as devtools show log;
import 'package:async/async.dart' show StreamGroup;

import 'package:testingisolates_course/person.dart';

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

// Future<Iterable<Todo>> getTodos() async {
//   final rp = ReceivePort();
//   await Isolate.spawn(_getTodos, rp.sendPort);
//   return await rp.first;
// }

void _getTodos(SendPort sp) async {
  const url = 'https://jsonplaceholder.typicode.com/todos';
  final todos = await http
      .get(Uri.parse(url))
      .then((response) => json.decode(response.body) as List<dynamic>)
      .then((json) => json.map((map) => Todo.fromJson(map)));

  Isolate.exit(sp, todos);
}

// ReceivePort is a stream of results that come from main function i.e. _getMessages(SendPort sp)
// asyncExpand changing data type of the stream i.e. from stream of isolates to ReceivePort
Stream<String> getMessages() {
  final rp = ReceivePort();
  return Isolate.spawn(_getMessages, rp.sendPort)
      .asStream()
      .asyncExpand((_) => rp)
      .takeWhile((element) => element is String)
      .cast();
}

void _getMessages(SendPort sp) async {
  await for (final now in Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now().toIso8601String(),
  ).take(10)) {
    sp.send(now);
  }
  Isolate.exit(sp);
}

@immutable
class PersonsRequest {
  final ReceivePort receivePort;
  final Uri uri;

  const PersonsRequest(this.receivePort, this.uri);

  static Iterable<PersonsRequest> all() sync* {
    for (final i in Iterable.generate(3, (i) => i)) {
      yield PersonsRequest(
        ReceivePort(),
        Uri.parse('http://127.0.0.1:5500/apis/people${i + 1}.json'),
      );
    }
  }
}

@immutable
class Request {
  final SendPort sendPort;
  final Uri uri;
  const Request(this.sendPort, this.uri);

  Request.fromPersonsRequest(PersonsRequest request)
      : sendPort = request.receivePort.sendPort,
        uri = request.uri;
}

Stream<Iterable<Person>> getPersons() {
  final streams = PersonsRequest.all().map((req) =>
      Isolate.spawn(_getPersons, Request.fromPersonsRequest(req))
          .asStream()
          .asyncExpand((event) => req.receivePort)
          .takeWhile((element) => element is Iterable<Person>)
          .cast());
  return StreamGroup.merge(streams).cast();
}

void _getPersons(Request request) async {
  final persons = await http
      .get(request.uri)
      .then((response) => json.decode(response.body) as List<dynamic>)
      .then((json) => json.map((map) => Person.fromMap(map)));

  Isolate.exit(request.sendPort, persons);
  //request.sendPort.send(persons);
}

void testIt() async {
  await for (final msg in getPersons()) {
    msg.log();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
        ),
        body: TextButton(
          onPressed: () {
            // final todos = getMessages();
            // todos.log();
            testIt();
          },
          child: const Text("Click Me"),
        ));
  }
}
