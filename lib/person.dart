// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

@immutable
class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'age': age,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      name: map['name'] as String,
      age: map['age'] as int,
    );
  }

  @override
  String toString() => 'Person(name: $name, age: $age)';
}
