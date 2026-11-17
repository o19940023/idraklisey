import 'package:flutter/material.dart';
import 'api_library_screen.dart';

/// Kitab İcarələri Ekranı — Canlı API bazası ilə sinxronlaşdırılmışdır
class BookLoansScreen extends StatelessWidget {
  const BookLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ApiLibraryScreen(initialTab: 1);
  }
}
