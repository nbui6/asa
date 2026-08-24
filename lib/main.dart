/// Asa — the shell.
///
/// One product, several hubs. Only the Product Hub exists.
library;

import 'package:flutter/material.dart';

import 'hubs/product/projects_screen.dart';

void main() {
  runApp(const AsaApp());
}

class AsaApp extends StatelessWidget {
  const AsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FEB)),
        useMaterial3: true,
      ),
      home: const ProjectsScreen(),
    );
  }
}
