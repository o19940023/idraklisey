import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'ticket_categories_screen.dart';
import 'tickets_list_view.dart';

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isStaff = session.profile?.isStaff == true;
    final canViewCategories = session.profile?.isSuper == true ||
        session.can('gopanel.tickets.categories.view') ||
        isStaff;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: const Text(
          'Dəstək Biletləri (Helpdesk)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5),
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (canViewCategories)
            IconButton(
              icon: const Icon(Icons.category_rounded),
              tooltip: 'Bilet Kateqoriyaları',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TicketCategoriesScreen()),
                );
              },
            ),
        ],
      ),
      body: TicketsListView(isStaff: isStaff),
    );
  }
}
