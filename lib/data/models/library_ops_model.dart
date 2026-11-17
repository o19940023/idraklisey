/// Models for library operations: loans, tracking, and reservations.
class BookLoan {
  final String id;
  final String bookId;
  final String bookTitle;
  final String author;
  final String borrowerId;
  final String borrowerName;
  final String borrowerRole; // 'student', 'teacher', 'admin'
  final DateTime loanDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String status; // 'active', 'returned', 'overdue'

  const BookLoan({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.author,
    required this.borrowerId,
    required this.borrowerName,
    this.borrowerRole = 'student',
    required this.loanDate,
    required this.dueDate,
    this.returnDate,
    this.status = 'active',
  });

  bool get isReturned => status == 'returned' || returnDate != null;
  bool get isOverdue => !isReturned && DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'book_id': bookId,
        'book_title': bookTitle,
        'author': author,
        'borrower_id': borrowerId,
        'borrower_name': borrowerName,
        'borrower_role': borrowerRole,
        'loan_date': loanDate.toIso8601String(),
        'due_date': dueDate.toIso8601String(),
        'return_date': returnDate?.toIso8601String(),
        'status': status,
      };

  factory BookLoan.fromJson(Map<String, dynamic> json) => BookLoan(
        id: json['id']?.toString() ?? '',
        bookId: json['book_id']?.toString() ?? '',
        bookTitle: json['book_title']?.toString() ?? '',
        author: json['author']?.toString() ?? '',
        borrowerId: json['borrower_id']?.toString() ?? '',
        borrowerName: json['borrower_name']?.toString() ?? '',
        borrowerRole: json['borrower_role']?.toString() ?? 'student',
        loanDate: json['loan_date'] != null
            ? DateTime.tryParse(json['loan_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        dueDate: json['due_date'] != null
            ? DateTime.tryParse(json['due_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        returnDate: json['return_date'] != null
            ? DateTime.tryParse(json['return_date'].toString())
            : null,
        status: json['status']?.toString() ?? 'active',
      );
}

/// Book reservation item.
class BookReservation {
  final String id;
  final String bookId;
  final String bookTitle;
  final String author;
  final String reserverId;
  final String reserverName;
  final DateTime reservationDate;
  final DateTime expiryDate;
  final String status; // 'pending', 'fulfilled', 'cancelled'

  const BookReservation({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.author,
    required this.reserverId,
    required this.reserverName,
    required this.reservationDate,
    required this.expiryDate,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'book_id': bookId,
        'book_title': bookTitle,
        'author': author,
        'reserver_id': reserverId,
        'reserver_name': reserverName,
        'reservation_date': reservationDate.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'status': status,
      };

  factory BookReservation.fromJson(Map<String, dynamic> json) => BookReservation(
        id: json['id']?.toString() ?? '',
        bookId: json['book_id']?.toString() ?? '',
        bookTitle: json['book_title']?.toString() ?? '',
        author: json['author']?.toString() ?? '',
        reserverId: json['reserver_id']?.toString() ?? '',
        reserverName: json['reserver_name']?.toString() ?? '',
        reservationDate: json['reservation_date'] != null
            ? DateTime.tryParse(json['reservation_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        expiryDate: json['expiry_date'] != null
            ? DateTime.tryParse(json['expiry_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        status: json['status']?.toString() ?? 'pending',
      );
}
