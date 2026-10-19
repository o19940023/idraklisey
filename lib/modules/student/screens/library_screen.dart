import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../providers/app_state.dart';
import '../../../data/models/library_model.dart';
import '../../../l10n/app_localizations.dart';

class LibraryScreen extends StatefulWidget {
  final bool isTeacherView;

  const LibraryScreen({super.key, this.isTeacherView = false});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedCategory = 'Hamısı';
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _defaultCategories = [
    'Dərslik',
    'IB Resurs',
    'Bədii',
    'Elmi',
    'Xarici Dil',
  ];

  List<String> _categoriesFor(List<BookItem> allBooks) {
    final cats = <String>[];
    for (final b in allBooks) {
      if (b.category.isNotEmpty && !cats.contains(b.category)) {
        cats.add(b.category);
      }
    }
    if (cats.isEmpty) cats.addAll(_defaultCategories);
    return ['Hamısı', ...cats];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = Provider.of<AppState>(context);
    final allBooks = appState.books;
    final categories = _categoriesFor(allBooks);

    final query = _searchCtrl.text.toLowerCase().trim();
    final filtered = allBooks.where((book) {
      final matchesCategory =
          _selectedCategory == 'Hamısı' || book.category == _selectedCategory;
      final matchesSearch =
          query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.isbn.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    final currentUser = appState.currentUser;
    final canAddBook =
        currentUser?.role == UserRole.teacher ||
        currentUser?.role == UserRole.admin;
    final myBorrowedCount = allBooks.where((b) => b.isBorrowedByMe).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canAddBook
          ? FloatingActionButton.extended(
              onPressed: () => _showAddBookDialog(context, appState),
              backgroundColor: AppColors.primaryAccent,
              elevation: 4,
              icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
              label: Text(
                '${loc.add} (${loc.library})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Academic Midnight Header ──
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F172A),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
              ),
              onPressed: () => handleBackNavigation(context),
            ),
            actions: [
              if (canAddBook)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    ),
                    tooltip: '${loc.add} (${loc.library})',
                    onPressed: () => _showAddBookDialog(context, appState),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E3A8A)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -15,
                      bottom: -15,
                      child: Icon(Icons.menu_book_rounded, size: 135, color: Colors.white.withAlpha(10)),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.local_library_rounded, size: 22, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isTeacherView
                                          ? '${loc.teacher} ${loc.library}'
                                          : loc.library,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${allBooks.length} kitab fondu • $myBorrowedCount aktiv oxucu icarəsi',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(180),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search & Filter Sliver ──
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Column(
                children: [
                  // Modern search field
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '${loc.search} (ad, müəllif, ISBN)...',
                      hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryAccent, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Categories ribbon
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        final label = cat == 'Hamısı' ? loc.all : cat;
                        final count = cat == 'Hamısı'
                            ? allBooks.length
                            : allBooks.where((b) => b.category == cat).length;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _selectedCategory = cat),
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryAccent : AppColors.background,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryAccent : AppColors.cardBorder,
                                  width: isSelected ? 1.3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryAccent.withAlpha(50),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withAlpha(40)
                                          : AppColors.cardBorder.withAlpha(60),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Catalog Body Sliver ──
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        loc.noResultsFound,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Axtarış sözünü dəyişin və ya başqa kateqoriya seçin.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildBookCard(context, appState, filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookCard(
    BuildContext context,
    AppState appState,
    BookItem book,
  ) {
    final loc = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: book.isBorrowedByMe
              ? AppColors.success.withAlpha(80)
              : AppColors.cardBorder,
          width: book.isBorrowedByMe ? 1.4 : 1,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover with drop shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 78,
                height: 110,
                color: AppColors.primaryAccent.withAlpha(15),
                child: Image.network(
                  book.coverUrl,
                  width: 78,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 78,
                      height: 110,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_rounded, color: Colors.white70, size: 28),
                          SizedBox(height: 4),
                          Text(
                            'İDRAK',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD4AF37),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details & Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        book.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.goldDark, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '${book.rating}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      book.pageCount > 0
                          ? '${book.pageCount} səh. • ${book.language}'
                          : book.language,
                      style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: book.availableCopies > 0
                            ? const Color(0xFF10B981).withAlpha(15)
                            : AppColors.danger.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.availableCopies > 0
                            ? '${book.availableCopies} nüsxə'
                            : 'Nüsxə bitib',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: book.availableCopies > 0
                              ? const Color(0xFF10B981)
                              : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action Buttons
                Row(
                  children: [
                    if (book.type == BookType.ebook || book.type == BookType.both)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: AppColors.primaryAccent),
                          ),
                          onPressed: () => _showEBookReader(context, book),
                          icon: const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.primaryAccent),
                          label: const Text(
                            'E-Oxu',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryAccent),
                          ),
                        ),
                      ),
                    if (book.type == BookType.ebook || book.type == BookType.both)
                      const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: book.isBorrowedByMe
                              ? AppColors.success
                              : (book.availableCopies <= 0 ? Colors.grey.shade400 : AppColors.primaryAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          elevation: 0,
                        ),
                        onPressed: (!book.isBorrowedByMe && book.availableCopies <= 0)
                            ? null
                            : () {
                                appState.toggleBorrowBook(book.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      book.isBorrowedByMe
                                          ? '"${book.title}" ${loc.returnBook}.'
                                          : '"${book.title}" ${loc.borrowBook}!',
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        icon: Icon(
                          book.isBorrowedByMe
                              ? Icons.check_circle_rounded
                              : Icons.bookmark_add_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: Text(
                          book.isBorrowedByMe
                              ? loc.bookBorrowed
                              : (book.availableCopies <= 0 ? 'Bitib' : loc.borrowBook),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (book.isBorrowedByMe && book.returnDeadline != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${loc.deadline}: ${dateFormat.format(book.returnDeadline!)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog(BuildContext context, AppState appState) {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final pageCtrl = TextEditingController(text: '200');
    final descCtrl = TextEditingController();
    final dialogCategories = _categoriesFor(appState.books).skip(1).toList();
    String category = dialogCategories.isNotEmpty ? dialogCategories.first : 'Dərslik';
    String language = 'Azərbaycan';
    BookType bookType = BookType.both;

    showDialog(
      context: context,
      builder: (ctx) {
        final dLoc = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.library_add_rounded, color: AppColors.primaryAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('${dLoc.add} (${dLoc.library})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Kitabın Adı *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: authorCtrl,
                      decoration: InputDecoration(
                        labelText: 'Müəllif *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: 'Kateqoriya',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: dialogCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Səhifə Sayı',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Qısa Təsvir / Xülasə',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(dLoc.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty || authorCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Zəhmət olmasa kitab adı və müəllifi daxil edin!')),
                      );
                      return;
                    }
                    final newBook = BookItem(
                      id: 'bk_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      author: authorCtrl.text.trim(),
                      category: category,
                      description: descCtrl.text.trim().isNotEmpty
                          ? descCtrl.text.trim()
                          : 'İdrak Liseyi rəsmi tədris vəsaiti.',
                      coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400',
                      type: bookType,
                      pageCount: int.tryParse(pageCtrl.text.trim()) ?? 150,
                      rating: 4.8,
                      language: language,
                      availableCopies: 5,
                    );
                    appState.addBook(newBook);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${newBook.title}" ${dLoc.successfullySaved}!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Text(dLoc.add, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEBookReader(BuildContext context, BookItem book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            book.author,
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, size: 52, color: Color(0xFFEF4444)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Rəqəmsal Dərslik / PDF Oxucu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${book.pageCount} səhifəlik rəsmi PDF nüsxəsi daxili oxucuya yüklənir...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('E-Kitab offline oxumaq üçün keşləndi.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Offline Saxla və Oxu',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
