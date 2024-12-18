import 'package:flutter/material.dart';
import 'package:quotify/quotes.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter App',
      home: Scaffold(
        body: MainApp(),

      ),
    );
  }
}