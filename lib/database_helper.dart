import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Book {
  final int id;
  final String title;
  final String authorName;
  final String coverImageUrl;
  final String readOnlineUrl;
  final int categoryId;

  Book({
    required this.id,
    required this.title,
    required this.authorName,
    required this.coverImageUrl,
    required this.readOnlineUrl,
    required this.categoryId,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      authorName: map['author_name'],
      coverImageUrl: map['cover_image_url'],
      readOnlineUrl: map['read_online_url'],
      categoryId: map['category_id'],
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
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

    return await openDatabase(path, readOnly: true);
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

  Future<List<CategoryWithBooks>> getBooksGroupedByCategory({int maxBooksPerCategory = 5}) async {
    final db = await database;
    
    // Get all categories
    List<Map<String, dynamic>> categoryMaps = await db.query('categories');
    List<Category> categories = categoryMaps.map((map) => Category.fromMap(map)).toList();
    
    List<CategoryWithBooks> result = [];
    
    for (Category category in categories) {
      // Get books for this category (limited to maxBooksPerCategory)
      List<Map<String, dynamic>> bookMaps = await db.query(
        'books',
        where: 'category_id = ?',
        whereArgs: [category.id],
        limit: maxBooksPerCategory,
      );
      
      List<Book> books = bookMaps.map((map) => Book.fromMap(map)).toList();
      
      result.add(CategoryWithBooks(
        category: category,
        books: books,
      ));
    }
    
    return result;
  }

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('books');
    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }
} 