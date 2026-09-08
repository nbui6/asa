/// Asa — the shell.
///
/// One product, several hubs. Only the Product Hub exists.
library;

import 'package:asa/hubs/product/projects_screen.dart';
import 'package:asa/local/local_hubs.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AsaApp());
}

class AsaApp extends StatelessWidget {
  const AsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The one registration point for a fork's own hubs — see
    // lib/local/local_hubs.dart and FOR-YOUR-FORK.md. localHubs is empty
    // in this repository, so `hubs.first` is always the Product Hub and
    // nothing here changes what ships.
    final hubs = <WidgetBuilder>[
      (context) => const ProjectsScreen(),
      ...localHubs,
    ];

    return MaterialApp(
      title: 'Asa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FEB)),
        useMaterial3: true,
      ),
      home: Builder(builder: hubs.first),
    );
  }
}
