import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Book {
  final int id;
  final int? gutenbergId;
  final String title;
  final String? subtitle;
  final int? authorId;
  final String? authorName;
  final int? categoryId;
  final int? languageId;
  final String? languageCode;
  final int? publicationYear;
  final int? pages;
  final int? wordCount;
  final String? description;
  final String? tags;
  final double? rating;
  final int? ratingCount;
  final String? difficultyLevel;
  final int? readingTimeMinutes;
  final bool? isPopular;
  final bool? isFeatured;
  final String? bookPageUrl;
  final String? coverImageUrl;
  final String? readOnlineUrl;
  final String? epubDownloadUrl;
  final String? pdfDownloadUrl;
  final String? txtDownloadUrl;
  final double? epubSizeMb;
  final double? pdfSizeMb;
  final double? txtSizeMb;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Book({
    required this.id,
    this.gutenbergId,
    required this.title,
    this.subtitle,
    this.authorId,
    this.authorName,
    this.categoryId,
    this.languageId,
    this.languageCode,
    this.publicationYear,
    this.pages,
    this.wordCount,
    this.description,
    this.tags,
    this.rating,
    this.ratingCount,
    this.difficultyLevel,
    this.readingTimeMinutes,
    this.isPopular,
    this.isFeatured,
    this.bookPageUrl,
    this.coverImageUrl,
    this.readOnlineUrl,
    this.epubDownloadUrl,
    this.pdfDownloadUrl,
    this.txtDownloadUrl,
    this.epubSizeMb,
    this.pdfSizeMb,
    this.txtSizeMb,
    this.createdAt,
    this.updatedAt,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      gutenbergId: map['gutenberg_id'],
      title: map['title'],
      subtitle: map['subtitle'],
      authorId: map['author_id'],
      authorName: map['author_name'],
      categoryId: map['category_id'],
      languageId: map['language_id'],
      languageCode: map['language_code'],
      publicationYear: map['publication_year'],
      pages: map['pages'],
      wordCount: map['word_count'],
      description: map['description'],
      tags: map['tags'],
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      ratingCount: map['rating_count'],
      difficultyLevel: map['difficulty_level'],
      readingTimeMinutes: map['reading_time_minutes'],
      isPopular: map['is_popular'] == 1 || map['is_popular'] == true,
      isFeatured: map['is_featured'] == 1 || map['is_featured'] == true,
      bookPageUrl: map['book_page_url'],
      coverImageUrl: map['cover_image_url'],
      readOnlineUrl: map['read_online_url'],
      epubDownloadUrl: map['epub_download_url'],
      pdfDownloadUrl: map['pdf_download_url'],
      txtDownloadUrl: map['txt_download_url'],
      epubSizeMb: map['epub_size_mb'] != null ? (map['epub_size_mb'] as num).toDouble() : null,
      pdfSizeMb: map['pdf_size_mb'] != null ? (map['pdf_size_mb'] as num).toDouble() : null,
      txtSizeMb: map['txt_size_mb'] != null ? (map['txt_size_mb'] as num).toDouble() : null,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? description;
  final int? bookCount;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.bookCount,
    this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      bookCount: map['book_count'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }
}

class CategoryWithBooks {
  final Category category;
  final List<Book> books;

  CategoryWithBooks({
    required this.category,
    required this.books,
  });
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'ebook_library.db');

    // Check if database exists
    bool exists = await databaseExists(path);

    if (!exists) {
      // Copy from assets
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join('assets', 'database', 'ebook_library.db'));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
    }

    return await openDatabase(path);
  }

  // Method to force refresh the database from assets
  Future<void> refreshDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'ebook_library.db');

    // Close existing database connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete existing database file
    try {
      await File(path).delete();
    } catch (e) {
      // File might not exist, ignore error
    }

    // Reinitialize database
    await _initDatabase();
  }

  Future<List<Book>> getBooksForCategory(int categoryId, {int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT books.* FROM books
      INNER JOIN book_categories ON books.id = book_categories.book_id
      WHERE book_categories.category_id = ?
      ORDER BY RANDOM()
      LIMIT ?
    ''', [categoryId, limit]);
    return maps.map((map) => Book.fromMap(map)).toList();
  }

  Future<List<CategoryWithBooks>> getCategoriesWithBooks({int maxBooksPerCategory = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> categoryMaps = await db.query('categories');
    List<CategoryWithBooks> result = [];
    for (final catMap in categoryMaps) {
      final category = Category.fromMap(catMap);
      final books = await getBooksForCategory(category.id, limit: maxBooksPerCategory);
      result.add(CategoryWithBooks(category: category, books: books));
    }
    return result;
  }

  Future<List<Book>> searchBooks(String query, {int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM books
      WHERE LOWER(title) LIKE ? OR LOWER(author_name) LIKE ?
      ORDER BY title COLLATE NOCASE
      LIMIT ?
    ''', ['%${query.toLowerCase()}%', '%${query.toLowerCase()}%', limit]);
    return maps.map((map) => Book.fromMap(map)).toList();
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<void> insertOrIgnoreBook(Book book, int categoryId) async {
    final db = await database;
    // Insert book if not exists
    await db.insert(
      'books',
      {
        'id': book.id,
        'title': book.title,
        'author_name': book.authorName,
        'cover_image_url': book.coverImageUrl,
        'epub_download_url': book.epubDownloadUrl,
        'pdf_download_url': book.pdfDownloadUrl,
        'txt_download_url': book.txtDownloadUrl,
        // Add other fields as needed
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    // Insert category mapping if not exists
    await db.insert(
      'book_categories',
      {
        'book_id': book.id,
        'category_id': categoryId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> insertOrIgnoreCategory(Category category) async {
    final db = await database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'description': category.description,
        'book_count': category.bookCount,
        'created_at': category.createdAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteBooksNotInList(int categoryId, Set<dynamic> keepBookIds) async {
    final db = await database;
    // Get all book_ids for this category
    final List<Map<String, dynamic>> maps = await db.query('book_categories', where: 'category_id = ?', whereArgs: [categoryId]);
    final localBookIds = maps.map((m) => m['book_id']).toSet();
    final idsToDelete = localBookIds.difference(keepBookIds);
    for (final bookId in idsToDelete) {
      // Remove from book_categories
      await db.delete('book_categories', where: 'book_id = ? AND category_id = ?', whereArgs: [bookId, categoryId]);
      // Optionally, remove from books table if not in any other category
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM book_categories WHERE book_id = ?', [bookId]));
      if (count == 0) {
        await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
      }
    }
  }
} 