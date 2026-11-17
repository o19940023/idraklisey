import 'package:flutter/foundation.dart';

import '../data/models/library_model.dart';
import '../services/firestore_service.dart';

/// Lisey kitabxanasının kitab siyahısı (liste.txt-dən) və Firebase-ə toplu yükləmə.
///
/// PDF faylları sonradan əlavə olunacaq — hazırda bütün kitablar fiziki
/// (BookType.physical) kimi qeydə alınır və pdfUrl boş qalır.
class BooksImportHelper {
  BooksImportHelper._();

  static final FirestoreService _firestoreService = FirestoreService();

  /// Siyahıdakı unikal kitab sayı
  static int get count => _getLiseyBooksData().length;

  /// Bütün kitabları Firebase-ə yükləyir (mövcud kitablar əvəz olunur)
  static Future<void> importLiseyBooks() async {
    final books = _getLiseyBooksData();
    await _firestoreService.importBooks(books);
    debugPrint('✅ ${books.length} Lisey kitabı Firebase-ə yükləndi');
  }

  /// Placeholder üz qabığı — bütün kitablar üçün eyni şəkil istifadə olunur
  static const String _coverUrl =
      'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400';

  static BookItem _b(
    String id,
    String title,
    String author,
    String category, {
    String isbn = '',
    String lang = 'Azərbaycan',
    int copies = 1,
  }) {
    return BookItem(
      id: id,
      title: title,
      author: author,
      category: category,
      coverUrl: _coverUrl,
      type: BookType.physical,
      pageCount: 0,
      language: lang,
      availableCopies: copies,
      totalCopies: copies,
      isbn: isbn,
      pdfUrl: '',
      description: '',
    );
  }

  static List<BookItem> _getLiseyBooksData() {
    return [
      _b('İDR-BAK-BOOK-3593', 'Lirika', 'Nizami Gəncəvi', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-417-05-3'),
      _b('İDR-BAK-BOOK-3594', 'Leyli və Məcnun', 'Nizami Gəncəvi', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-417-04-5'),
      _b('İDR-BAK-BOOK-3595', 'Yeddi Gözəl', 'Nizami Gəncəvi', 'Klassik Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3596', 'Xosrov və Şirin', 'Nizami Gəncəvi', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-417-08-8'),
      _b('İDR-BAK-BOOK-3597', 'Sirlər xəzinəsi', 'Nizami Gəncəvi', 'Klassik Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3598', 'İskəndərnamə İqbalnamə', 'Nizami Gəncəvi', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-417-02-9'),
      _b('İDR-BAK-BOOK-3599', 'İskəndərnamə Şərəfnamə', 'Nizami Gəncəvi', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-417-03-7'),
      _b('İDR-BAK-BOOK-3600', 'Seçilmiş əsərləri I Cild', 'Seyid Əzim Şirvani', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-421-00-X'),
      _b('İDR-BAK-BOOK-3601', 'Seşçilmiş əsərləri II Cild', 'Seyid Əzim Şirvani', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-421-02-6'),
      _b('İDR-BAK-BOOK-3602', 'Seçilmiş əsərləri III Cild', 'Seyid Əzim Şirvani', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-421-01-8'),
      _b('İDR-BAK-BOOK-3603', 'Seçilmiş əsərləri I Cild', 'Mirzə Fətəli Axundzadə', 'Klassik Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3604', 'Seçilmiş əsərləri II Cild', 'Mirzə Fətəli Axundzadə', 'Klassik Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3605', 'Seçilmiş əsərləri III Cild', 'Mirzə Fətəli Axundzadə', 'Klassik Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3606', 'Əsərləri I Cild', 'Cəlil Məmmədquluzadə', 'Klassik Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3607', 'Əsərləri II Cild', 'Cəlil Məmmədquluzadə', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-416-18-X'),
      _b('İDR-BAK-BOOK-3608', 'Əsərləri III Cild', 'Cəlil Məmmədquluzadə', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-416-19-8'),
      _b('İDR-BAK-BOOK-3609', 'Seçilmiş əsərləri IV Cild', 'Cəlil Məmmədquluzadə', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-416-20-1'),
      _b('İDR-BAK-BOOK-3610', 'Əsərləri I Cild', 'Cəfər Cabbarlı', 'Müasir Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3611', 'Əsərləri II Cild', 'Cəfər Cabbarlı', 'Müasir Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3612', 'Əsərləri III Cild', 'Cəfər Cabbarlı', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '9952-418-89-X'),
      _b('İDR-BAK-BOOK-3613', 'Əsərləri IV Cild', 'Cəfər Cabbarlı', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '9952-418-90-3'),
      _b('İDR-BAK-BOOK-3614', 'Əsərləri I Cild', 'Yusif Vəzir Çəmənzəminli', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-421-09-3'),
      _b('İDR-BAK-BOOK-3615', 'Əsərləri II Cild', 'Yusif Vəzir Çəmənzəminli', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-421-08-5'),
      _b('İDR-BAK-BOOK-3616', 'Əsərləri III Cild', 'Yusif Vəzir Çəmənzəminli', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-421-07-7'),
      _b('İDR-BAK-BOOK-3617', 'Əsərləri', 'Şah İsmayıl Xətayi', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-418-43-1'),
      _b('İDR-BAK-BOOK-3618', 'Seçilmiş əsərləri I Cild', 'Əbdürrəhim Bəy Haqverdiyev', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-417-37-1'),
      _b('İDR-BAK-BOOK-3619', 'Seçilmiş əsərləri II Cild', 'Əbdürrəhim Bəy Haqverdiyev', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-417-38-X'),
      _b('İDR-BAK-BOOK-3620', 'Əsərləri', 'Molla Cümə', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '10 9952-34-041-9. 13 978-9952-34-041-9'),
      _b('İDR-BAK-BOOK-3621', 'Seçilmiş əsərləri', 'Xaqani Şirvani', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-417-23-1'),
      _b('İDR-BAK-BOOK-3622', 'Azərbaycan ədəbiyyatı I Cild', 'Firidun Bəy Köçərli', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-421-16-6'),
      _b('İDR-BAK-BOOK-3623', 'Azərbaycan ədəbiyyatı II Cild', 'Firidun Bəy Köçərli', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-421-17-4'),
      _b('İDR-BAK-BOOK-3624', 'Seçilmiş əsərləri', 'Abbas Səhhət', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-417-32-0'),
      _b('İDR-BAK-BOOK-3625', 'Seçilmiş əsərləri', 'Tağı Şahbazi Simürğ', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '10 9952-34-040-0. 13 978-9952-34-040-2'),
      _b('İDR-BAK-BOOK-3626', 'Seçilmiş əsərləri', 'Məhəmməd Hadi', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-418-64-4'),
      _b('İDR-BAK-BOOK-3627', 'Nəğmələr', 'Mirzə Şəfi Vazeh', 'Klassik Azərbaycan Ədəbiyyatı', isbn: '9952-418-23-7'),
      _b('İDR-BAK-BOOK-3628', 'Əsərləri', 'Xurşudbanu Natəvan', 'Klassik Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3629', 'Seçilmiş əsərləri', 'Əhməd Cavad', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '9952-418-24-5'),
      _b('İDR-BAK-BOOK-3630', 'Seçilmiş əsərləri', 'Almas İldırım', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '9952-416-03-1'),
      _b('İDR-BAK-BOOK-3631', 'Seçilmiş əsərləri', 'Əli Bəy Hüseynzadə', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '978-9952-34-162-1'),
      _b('İDR-BAK-BOOK-3632', 'Seçilmiş əsərləri I cild', 'Rəsul Rza', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '9952-416-66-X'),
      _b('İDR-BAK-BOOK-3633', 'Seçilmiş əsərləri II cild', 'Rəsul Rza', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '9952-416-67-8'),
      _b('İDR-BAK-BOOK-3634', 'Seçilmiş əsərləri III cild', 'Rəsul Rza', 'Müasir Azərbaycan Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3635', 'Seçilmiş əsərləri IV cild', 'Rəsul Rza', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '9952-416-69-4'),
      _b('İDR-BAK-BOOK-3636', 'Seçilmiş əsərləri V cild', 'Rəsul Rza', 'Müasir Azərbaycan Ədəbiyyatı', isbn: '9952-416-70-8'),
      _b('İDR-BAK-BOOK-3637', 'Seçilmiş əsərləri', 'Nəcib Fazil Qısakürək', 'Müasir Dünya Ədəbiyyatı', isbn: '978-9952-34-291-8'),
      _b('İDR-BAK-BOOK-3638', 'Seçilmiş əsərləri II cild', 'A.S.Puşkin', 'Dünya Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3639', 'Seçilmiş əsərləri I cild', 'A.S.Puşkin', 'Dünya Ədəbiyyatı', isbn: '10 9952-421-38-7, 13 978-9952-421-38-5'),
      _b('İDR-BAK-BOOK-3640', 'Seçilmiş əsərləri', 'Lev Tolstoy', 'Dünya Ədəbiyyatı'),
      _b('İDR-BAK-BOOK-3641', 'Seçilmiş əsərlər', 'Hafiz Şirazi', 'Dünya Ədəbiyyatı', isbn: '9952-416-41-4'),
      _b('İDR-BAK-BOOK-3642', 'Seçilmiş əsərləri', 'Nazim Hikmət', 'Dünya Ədəbiyyatı', isbn: '10 9952-34-051-6, 13 978-9952-34-051-8'),
      _b('İDR-BAK-BOOK-3643', 'Məktəbin ibtidai siniflərində riyaziyyat tədrisinin metodikası', 'İ.İ.Həmidov', 'Metodik vəsait', copies: 3),
      _b('İDR-BAK-BOOK-3646', 'The Last Sherlock Holmes Story', 'Michael Dibdin', 'Dedektiv roman', lang: 'İngilis'),
      _b('İDR-BAK-BOOK-3647', 'Black Beauty', 'Anna Sewell', 'Uşaq klassik romanı', lang: 'İngilis'),
      _b('İDR-BAK-BOOK-3648', 'Alice s Adventures in Wonderland', 'Lewis Carroll', 'Fantastik uşaq romanı', lang: 'İngilis', copies: 2),
      _b('İDR-BAK-BOOK-3650', 'Stories from Shakespeare', 'William Shakespeare', 'Klassik ədəbiyyat', isbn: '0 582 426944', lang: 'İngilis', copies: 2),
      _b('İDR-BAK-BOOK-3653', 'Robinson Crusoe', 'Daniel Defoe', 'Klassik ədəbiyyat', isbn: '0 582 426 960', lang: 'İngilis', copies: 3),
      _b('İDR-BAK-BOOK-3656', 'The Mummy Returns', 'John Whitman', 'Bədii ədəbiyyat', lang: 'İngilis', copies: 4),
      _b('İDR-BAK-BOOK-3660', 'The Monkey s Paw', 'W.W.Jacobs', 'Bədii ədəbiyyat', lang: 'İngilis', copies: 10),
      _b('İDR-BAK-BOOK-3669', 'The Man with Two Shadows and Other Ghost Stories', 'Thomas Hood and others', 'Nağıllar', lang: 'İngilis', copies: 5),
      _b('İDR-BAK-BOOK-3103', 'Məktəbdə əxlaq və davranış qaydaları', 'Nazim Əkbərov', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-00-1', copies: 5),
      _b('İDR-BAK-BOOK-3108', 'Ailə və Cəmiyyətdə əxlaq və davranış qaydaları', 'Nazim Əkbərov', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-01-8', copies: 5),
      _b('İDR-BAK-BOOK-3113', 'Nə,Necə,Nə üçün?-1', 'Əsli Qaplan', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-08-7', copies: 5),
      _b('İDR-BAK-BOOK-3118', 'Nə,Necə,Nə üçün?-2', 'Aslı Kaplan', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-16-2', copies: 5),
      _b('İDR-BAK-BOOK-3123', 'Zəka sualları', 'Ersin Osman Söyütlü', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-07-0', copies: 5),
      _b('İDR-BAK-BOOK-3128', 'Xəzinənin açarı', 'Bestami Yazqan', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-12-4', copies: 5),
      _b('İDR-BAK-BOOK-3133', 'Hörümçək tuneli', 'Zeynep Kayadelen', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-03-2', copies: 5),
      _b('İDR-BAK-BOOK-3138', 'Ulu ağacın tilsimi', 'Rabia Kandıra', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-09-4', copies: 5),
      _b('İDR-BAK-BOOK-3143', 'Bərəkətli sünbüllər', 'Ruhi Dəmirəl', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-29-2', copies: 5),
      _b('İDR-BAK-BOOK-3148', 'Basdırılmış pul', 'Həsən Qoca', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-10-0', copies: 5),
      _b('İDR-BAK-BOOK-3153', 'Əbdülün macəraları', 'Sədrəddin Hüseyn', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-19-3', copies: 5),
      _b('İDR-BAK-BOOK-3158', '"Məsnəvi" dən seçmələr', 'Mövlanə Cəlaləddin Rumi', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-11-7', copies: 5),
      _b('İDR-BAK-BOOK-3163', 'Əyləncəli suallar', 'Ersin Osman Söyütlü', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-02-5', copies: 3),
      _b('İDR-BAK-BOOK-3166', 'Bayquş Həkim', 'Osman Qaplan', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-22-3', copies: 5),
      _b('İDR-BAK-BOOK-3171', 'Gülən mağara', 'Bəkir Sidqi Turxan', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-26-1', copies: 5),
      _b('İDR-BAK-BOOK-3176', 'Sirli səyahət', 'İsmayıl Abay,Səfa Ənəs Ərgün', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-18-6', copies: 5),
      _b('İDR-BAK-BOOK-3181', 'Vəfalı dəvə', 'Aişə Güllüoğlu', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-34-6', copies: 5),
      _b('İDR-BAK-BOOK-3186', 'Qusar Tarzanı', 'Bəkir Sidqi Turxan', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-38-4', copies: 5),
      _b('İDR-BAK-BOOK-3191', 'Velosipedçi panda', 'Aişə Güllüoğlu', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-23-0', copies: 5),
      _b('İDR-BAK-BOOK-3196', 'Sevimli velosipedim', 'Ərsin Osman Söyüdlü', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-41-4', copies: 5),
      _b('İDR-BAK-BOOK-3201', 'Zəngli saatım olmasaydı', 'Ərsin Osman Söyüdlü', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-25-4', copies: 5),
      _b('İDR-BAK-BOOK-3206', 'Qurbağanın arzusu', 'Osman Qaplan', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-33-9', copies: 5),
      _b('İDR-BAK-BOOK-3211', 'Qoçaq Xallı', 'Vəhib Sinan', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-17-9', copies: 5),
      _b('İDR-BAK-BOOK-3216', 'Dostluğun şərti', 'Mələk Altun', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-05-6', copies: 5),
      _b('İDR-BAK-BOOK-3221', 'Əyləncəli suallar', 'Ərsin Osman Söyüdlü', 'Uşaq ədəbiyyatı', isbn: '978-9952-457-02-5', copies: 2),
    ];
  }
}
