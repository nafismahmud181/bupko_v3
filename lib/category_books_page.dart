import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'book_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryBooksPage extends StatefulWidget {
  final Category category;
  const CategoryBooksPage({super.key, required this.category});

  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadBooksHybrid();
  }

  Future<List<Book>> _loadBooksHybrid({bool forceRefresh = false}) async {
    final localBooks = await DatabaseHelper().getBooksForCategory(widget.category.id, limit: 100);
    if (localBooks.isNotEmpty && !forceRefresh) {
      return localBooks;
    }
    // Fetch from Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.category.name)
        .collection('books')
        .get();
    final firestoreBooks = snapshot.docs.map((doc) {
      final data = doc.data();
      return Book(
        id: data['id'] ?? doc.id.hashCode,
        title: data['title'] ?? '',
        authorName: data['authorName'],
        coverImageUrl: data['coverImageUrl'],
        epubDownloadUrl: data['epubDownloadUrl'],
        pdfDownloadUrl: data['pdfDownloadUrl'],
        txtDownloadUrl: data['txtDownloadUrl'],
      );
    }).toList();
    // Mirror Firestore: delete local books not in Firestore
    final firestoreBookIds = firestoreBooks.map((b) => b.id).toSet();
    await DatabaseHelper().deleteBooksNotInList(widget.category.id, firestoreBookIds);
    // Insert/update Firestore books into local DB
    for (final book in firestoreBooks) {
      await DatabaseHelper().insertOrIgnoreBook(book, widget.category.id);
    }
    return await DatabaseHelper().getBooksForCategory(widget.category.id, limit: 100);
  }

  void _refreshBooks() {
    setState(() {
      _booksFuture = _loadBooksHybrid(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outline.withValues(alpha:0.08),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync with Firestore',
            onPressed: _refreshBooks,
          ),
        ],
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error.withValues(alpha:0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: colorScheme.outline.withValues(alpha:0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No books found',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha:0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Books in this category will appear here',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha:0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BookCard(
                  book: book,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailsPage(book: book),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:theme.brightness == Brightness.dark ? 0.12 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                        ? Image.network(
                            book.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: colorScheme.surface,
                                child: Icon(
                                  Icons.book,
                                  size: 32,
                                  color: colorScheme.outline,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: colorScheme.surface,
                            child: Icon(
                              Icons.book,
                              size: 32,
                              color: colorScheme.outline,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (book.authorName != null && book.authorName!.isNotEmpty)
                        Text(
                          book.authorName!,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha:0.7), fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.outline.withValues(alpha:0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}