import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'book_details_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = DatabaseHelper().getAllCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                subtitle: category.description != null && category.description!.isNotEmpty
                    ? Text(category.description!)
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryBooksPage(category: category),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CategoryBooksPage extends StatelessWidget {
  final Category category;
  const CategoryBooksPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: FutureBuilder<List<Book>>(
        future: DatabaseHelper().getBooksForCategory(category.id, limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return const Center(child: Text('No books found in this category.'));
          }
          return ListView.separated(
            itemCount: books.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                    ? Image.network(book.coverImageUrl!, width: 40, height: 60, fit: BoxFit.cover)
                    : const Icon(Icons.book, size: 40),
                title: Text(book.title),
                subtitle: Text(book.authorName ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailsPage(book: book),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 