import 'package:flutter/material.dart';
import '../../library_ops/screens/api_library_screen.dart';

/// Kitabxana Ekranı — Canlı API bazası ilə 1:1 sinxron
class LibraryScreen extends StatelessWidget {
  final bool isTeacherView;

  const LibraryScreen({super.key, this.isTeacherView = false});

  @override
  Widget build(BuildContext context) {
    return const ApiLibraryScreen(initialTab: 0);
  }
}
