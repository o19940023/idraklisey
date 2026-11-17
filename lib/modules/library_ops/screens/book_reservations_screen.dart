import 'package:flutter/material.dart';
import 'api_library_screen.dart';

/// Kitab Rezervasiyaları Ekranı — Canlı API bazası ilə sinxronlaşdırılmışdır
class BookReservationsScreen extends StatelessWidget {
  const BookReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ApiLibraryScreen(initialTab: 0);
  }
}
