import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'search_page.dart';
import 'book_upload_form_page.dart';
import 'book_details_page.dart';
import 'category_books_page.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'epub_reader_page.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<CategoryWithBooks>>? _booksFuture;
  DownloadedBook? _lastDownloadedBook;
  Book? _lastBookInfo;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadLastDownloadedBook();
  }

  void _loadBooks() {
    setState(() {
      _booksFuture = DatabaseHelper().getCategoriesWithBooks(maxBooksPerCategory: 5);
    });
  }

  Future<void> _refreshDatabase() async {
    await DatabaseHelper().refreshDatabase();
    _loadBooks();
  }

  Future<void> _loadLastDownloadedBook() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = await dir.list().toList();
      List<DownloadedBook> books = [];
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          final extension = fileName.split('.').last.toLowerCase();
          if (["epub", "pdf", "txt"].contains(extension)) {
            final bookTitle = fileName.split('.').first.replaceAll('_', ' ');
            final fileSize = await file.length();
            final lastModified = await file.lastModified();
            books.add(DownloadedBook(
              title: bookTitle,
              filePath: file.path,
              fileSize: fileSize,
              lastModified: lastModified,
              fileType: extension,
            ));
          }
        }
      }
      books.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      if (books.isNotEmpty) {
        final last = books.first;
        // Try to get book ID from mapping file
        final mappingFile = File('${dir.path}/downloaded_books.json');
        int? bookId;
        if (await mappingFile.exists()) {
          final content = await mappingFile.readAsString();
          if (content.isNotEmpty) {
            final mapping = json.decode(content);
            if (mapping[last.filePath] != null) {
              bookId = mapping[last.filePath] is int
                ? mapping[last.filePath]
                : int.tryParse(mapping[last.filePath].toString());
            }
          }
        }
        Book? dbBook;
        if (bookId != null) {
          final db = await DatabaseHelper().database;
          final List<Map<String, dynamic>> maps = await db.query('books', where: 'id = ?', whereArgs: [bookId]);
          if (maps.isNotEmpty) {
            dbBook = Book.fromMap(maps.first);
          }
        }
        setState(() {
          _lastDownloadedBook = last;
          _lastBookInfo = dbBook;
        });
      }
    // ignore: empty_catches
    } catch (e) {
    }
  }

  PreferredSizeWidget buildFixedAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Text(
            'Bupko',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              Icon(Icons.notifications_none_rounded, size: 26, color: theme.colorScheme.onSurface),
              Positioned(
                right: 0,
                top: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget buildModernHeader(BuildContext context, {bool showLastDownloaded = true}) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.white
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: theme.brightness == Brightness.light ? 0.04 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search books, authors...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }


  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your library...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load your books right now',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshDatabase,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your library is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start building your digital library by uploading your first book',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookUploadFormPage()),
              ).then((_) => _loadLastDownloadedBook()),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload Your First Book'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksList(List<CategoryWithBooks> categories) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: buildModernHeader(context, showLastDownloaded: false)),
        if (_lastDownloadedBook != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _LastDownloadedBookCard(
                book: _lastBookInfo,
                downloaded: _lastDownloadedBook!,
                onResume: () async {
                  final file = File(_lastDownloadedBook!.filePath);
                  if (await file.exists()) {
                    if (_lastDownloadedBook!.fileType == 'epub') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EpubReaderPage(
                            filePath: _lastDownloadedBook!.filePath,
                            bookTitle: _lastDownloadedBook!.title,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening ${_lastDownloadedBook!.fileType.toUpperCase()} file...')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('File not found: ${_lastDownloadedBook!.title}')),
                    );
                  }
                },
                onRecap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recap feature coming soon!')),
                  );
                },
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ModernCategorySection(
              categoryWithBooks: categories[index],
              onBookTap: (book) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailsPage(book: book),
                  ),
                ).then((_) => _loadLastDownloadedBook());
              },
            ),
            childCount: categories.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BookUploadFormPage()),
        ).then((_) => _loadLastDownloadedBook()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Book'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: buildFixedAppBar(context),
      body: RefreshIndicator(
        onRefresh: _refreshDatabase,
        child: FutureBuilder<List<CategoryWithBooks>>(
          future: _booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }
            return _buildBooksList(snapshot.data!);
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }
}

class ModernCategorySection extends StatelessWidget {
  final CategoryWithBooks categoryWithBooks;
  final void Function(Book)? onBookTap;

  const ModernCategorySection({
    super.key,
    required this.categoryWithBooks,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoryWithBooks.category.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryBooksPage(category: categoryWithBooks.category),
                      ),
                    );
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categoryWithBooks.books.length,
              itemBuilder: (context, index) {
                final book = categoryWithBooks.books[index];
                return GestureDetector(
                  onTap: () => onBookTap?.call(book),
                  child: ModernBookCard(book: book),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ModernBookCard extends StatelessWidget {
  final Book book;

  const ModernBookCard({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                  ? Image.network(
                      book.coverImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : _buildPlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
          // Book Title
          Text(
            book.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Author
          Text(
            book.authorName ?? 'Unknown Author',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _LastDownloadedBookCard extends StatelessWidget {
  final Book? book;
  final DownloadedBook downloaded;
  final VoidCallback onResume;
  final VoidCallback onRecap;

  const _LastDownloadedBookCard({
    required this.book,
    required this.downloaded,
    required this.onResume,
    required this.onRecap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 251, 1).withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: book != null && book!.coverImageUrl != null && book!.coverImageUrl!.isNotEmpty
                ? Image.network(
                    book!.coverImageUrl!,
                    width: 80,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  downloaded.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book != null && book!.authorName != null && book!.authorName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      book!.authorName!,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha:0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Chapter 25', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Text('Page 334', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('58%', style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text('completed', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha:0.7))),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: onResume,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      ),
                      child: const Text('Resume'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: onRecap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      ),
                      child: const Text('Recap'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class DownloadedBook {
  final String title;
  final String filePath;
  final int fileSize;
  final DateTime lastModified;
  final String fileType;

  DownloadedBook({
    required this.title,
    required this.filePath,
    required this.fileSize,
    required this.lastModified,
    required this.fileType,
  });
}