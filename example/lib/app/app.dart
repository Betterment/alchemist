import 'package:example/home/home.dart';
import 'package:flutter/material.dart';

class AlchemistExampleApp extends StatelessWidget {
  const AlchemistExampleApp({super.key});

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
