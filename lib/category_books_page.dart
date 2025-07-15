import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'book_details_page.dart';

class CategoryBooksPage extends StatelessWidget {
  final Category category;
  const CategoryBooksPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          category.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.background,
        foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onBackground,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outline.withValues(alpha:0.08),
          ),
        ),
      ),
      body: FutureBuilder<List<Book>>(
        future: DatabaseHelper().getBooksForCategory(category.id, limit: 100),
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
                      color: colorScheme.onBackground.withValues(alpha:0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Books in this category will appear here',
                    style: TextStyle(
                      color: colorScheme.onBackground.withValues(alpha:0.5),
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
                    color: colorScheme.surfaceVariant,
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