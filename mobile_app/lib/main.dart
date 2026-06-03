import 'package:flutter/material.dart';

void main() {
  runApp(const ValideApp());
}

class ValideApp extends StatelessWidget {
  const ValideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valide School',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Valide School',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
