import 'package:flutter/material.dart';

import '../features/start/presentation/start_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'scenic_me',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const StartScreen(),
    );
  }
}
