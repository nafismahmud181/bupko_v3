import 'package:flutter/material.dart' as widgets;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'epub_reader_page.dart';

class LibraryPage extends widgets.StatefulWidget {
  const LibraryPage({super.key});

  @override
  widgets.State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends widgets.State<LibraryPage> with widgets.SingleTickerProviderStateMixin, widgets.WidgetsBindingObserver {
  List<DownloadedBook> _downloadedBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late widgets.AnimationController _animationController;
  late widgets.Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    widgets.WidgetsBinding.instance.addObserver(this);
    _animationController = widgets.AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = widgets.Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(widgets.CurvedAnimation(
      parent: _animationController,
      curve: widgets.Curves.easeInOut,
    ));
    _loadDownloadedBooks();
  }

  @override
  void dispose() {
    widgets.WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDownloadedBooks() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = await dir.list().toList();
      
      List<DownloadedBook> books = [];
      
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          final extension = fileName.split('.').last.toLowerCase();
          
          if (['epub', 'pdf', 'txt'].contains(extension)) {
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
      
      // Sort by last modified date (newest first)
      books.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      
      setState(() {
        _downloadedBooks = books;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<DownloadedBook> get _filteredBooks {
    if (_searchQuery.isEmpty) return _downloadedBooks;
    return _downloadedBooks.where((book) =>
        book.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _openBook(DownloadedBook book) async {
    try {
      final file = File(book.filePath);
      if (!await file.exists()) {
        widgets.ScaffoldMessenger.of(context).showSnackBar(
          widgets.SnackBar(
            content: widgets.Text('File not found: ${book.title}'),
            backgroundColor: widgets.Colors.red,
          ),
        );
        return;
      }

      if (book.fileType == 'epub') {
        widgets.Navigator.push(
          context,
          widgets.MaterialPageRoute(
            builder: (context) => EpubReaderPage(
              filePath: book.filePath,
              bookTitle: book.title,
            ),
          ),
        );
      } else {
        widgets.ScaffoldMessenger.of(context).showSnackBar(
          widgets.SnackBar(
            content: widgets.Text('Opening ${book.fileType.toUpperCase()} file...'),
          ),
        );
      }
    } catch (e) {
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        widgets.SnackBar(
          content: widgets.Text('Error opening book: $e'),
          backgroundColor: widgets.Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBook(DownloadedBook book) async {
    try {
      final file = File(book.filePath);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _downloadedBooks.remove(book);
        });
        widgets.ScaffoldMessenger.of(context).showSnackBar(
          widgets.SnackBar(
            content: widgets.Text('${book.title} deleted successfully'),
          ),
        );
      }
    } catch (e) {
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        widgets.SnackBar(
          content: widgets.Text('Error deleting book: $e'),
          backgroundColor: widgets.Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(DownloadedBook book) {
    widgets.showDialog(
      context: context,
      builder: (context) => widgets.AlertDialog(
        title: const widgets.Text('Delete Book'),
        content: widgets.Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          widgets.TextButton(
            onPressed: () => widgets.Navigator.of(context).pop(),
            child: const widgets.Text('Cancel'),
          ),
          widgets.TextButton(
            onPressed: () {
              widgets.Navigator.of(context).pop();
              _deleteBook(book);
            },
            style: widgets.TextButton.styleFrom(
              foregroundColor: widgets.Colors.red,
            ),
            child: const widgets.Text('Delete'),
          ),
        ],
      ),
    );
  }

  widgets.Widget _buildBookCard(DownloadedBook book) {
    final theme = widgets.Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return widgets.Card(
      margin: const widgets.EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: widgets.RoundedRectangleBorder(
        borderRadius: widgets.BorderRadius.circular(16),
        side: widgets.BorderSide(
          color: colorScheme.outline.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: widgets.InkWell(
        onTap: () => _openBook(book),
        borderRadius: widgets.BorderRadius.circular(16),
        child: widgets.Padding(
          padding: const widgets.EdgeInsets.all(16),
          child: widgets.Row(
            crossAxisAlignment: widgets.CrossAxisAlignment.start,
            children: [
              // Book Icon
              widgets.Container(
                width: 60,
                height: 80,
                decoration: widgets.BoxDecoration(
                  color: colorScheme.primary.withValues(alpha:0.1),
                  borderRadius: widgets.BorderRadius.circular(8),
                ),
                child: widgets.Icon(
                  book.fileType == 'epub' ? widgets.Icons.menu_book :
                  book.fileType == 'pdf' ? widgets.Icons.picture_as_pdf :
                  widgets.Icons.text_snippet,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const widgets.SizedBox(width: 16),
              // Book Info
              widgets.Expanded(
                child: widgets.Column(
                  crossAxisAlignment: widgets.CrossAxisAlignment.start,
                  children: [
                    widgets.Text(
                      book.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: widgets.FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: widgets.TextOverflow.ellipsis,
                    ),
                    const widgets.SizedBox(height: 4),
                    widgets.Row(
                      children: [
                        widgets.Container(
                          padding: const widgets.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: widgets.BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha:0.1),
                            borderRadius: widgets.BorderRadius.circular(12),
                          ),
                          child: widgets.Text(
                            book.fileType.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: widgets.FontWeight.w500,
                            ),
                          ),
                        ),
                        const widgets.SizedBox(width: 8),
                        widgets.Text(
                          _formatFileSize(book.fileSize),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha:0.6),
                          ),
                        ),
                      ],
                    ),
                    const widgets.SizedBox(height: 8),
                    widgets.Text(
                      'Downloaded ${_formatDate(book.lastModified)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha:0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              widgets.Column(
                children: [
                  widgets.IconButton(
                    onPressed: () => _openBook(book),
                    icon: widgets.Icon(
                      widgets.Icons.play_arrow,
                      color: colorScheme.primary,
                    ),
                    style: widgets.IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withValues(alpha:0.1),
                      shape: widgets.RoundedRectangleBorder(
                        borderRadius: widgets.BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const widgets.SizedBox(height: 4),
                  widgets.IconButton(
                    onPressed: () => _showDeleteDialog(book),
                    icon: widgets.Icon(
                      widgets.Icons.delete_outline,
                      color: widgets.Colors.red.withValues(alpha:0.7),
                    ),
                    style: widgets.IconButton.styleFrom(
                      backgroundColor: widgets.Colors.red.withValues(alpha:0.1),
                      shape: widgets.RoundedRectangleBorder(
                        borderRadius: widgets.BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(widgets.AppLifecycleState state) {
    if (state == widgets.AppLifecycleState.resumed) {
      _loadDownloadedBooks();
    }
  }

  @override
  widgets.Widget build(widgets.BuildContext context) {
    final theme = widgets.Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return widgets.Scaffold(
      backgroundColor: colorScheme.background,
      appBar: widgets.AppBar(
        title: widgets.Text(
          'My Library',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: widgets.FontWeight.bold,
          ),
        ),
        backgroundColor: widgets.Colors.transparent,
        elevation: 0,
        actions: [
          widgets.IconButton(
            onPressed: _loadDownloadedBooks,
            icon: const widgets.Icon(widgets.Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? widgets.Center(
              child: widgets.Column(
                mainAxisAlignment: widgets.MainAxisAlignment.center,
                children: [
                  widgets.CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                  const widgets.SizedBox(height: 16),
                  widgets.Text(
                    'Loading your library...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                  ),
                ],
              ),
            )
          : widgets.Padding(
              padding: const widgets.EdgeInsets.all(16),
              child: widgets.Column(
                crossAxisAlignment: widgets.CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  widgets.Container(
                    decoration: widgets.BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: widgets.BorderRadius.circular(16),
                      border: widgets.Border.all(
                        color: colorScheme.outline.withValues(alpha:0.1),
                      ),
                    ),
                    child: widgets.TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: widgets.InputDecoration(
                        hintText: 'Search your books...',
                        prefixIcon: widgets.Icon(
                          widgets.Icons.search,
                          color: colorScheme.onSurface.withValues(alpha:0.6),
                        ),
                        border: widgets.InputBorder.none,
                        contentPadding: const widgets.EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const widgets.SizedBox(height: 24),
                  // Stats Row
                  widgets.Row(
                    children: [
                      widgets.Text(
                        '${_filteredBooks.length} books',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: widgets.FontWeight.w600,
                        ),
                      ),
                      const widgets.Spacer(),
                      widgets.Text(
                        _downloadedBooks.fold<double>(0, (sum, book) => sum + book.fileSize / (1024 * 1024))
                            .toStringAsFixed(1) + ' MB total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha:0.6),
                        ),
                      ),
                    ],
                  ),
                  const widgets.SizedBox(height: 16),
                  // Books List
                  widgets.Expanded(
                    child: _filteredBooks.isEmpty
                        ? widgets.Center(
                            child: widgets.Column(
                              mainAxisAlignment: widgets.MainAxisAlignment.center,
                              children: [
                                widgets.Icon(
                                  widgets.Icons.library_books_outlined,
                                  size: 64,
                                  color: colorScheme.onSurface.withValues(alpha:0.3),
                                ),
                                const widgets.SizedBox(height: 16),
                                widgets.Text(
                                  _searchQuery.isEmpty 
                                      ? 'No books downloaded yet' 
                                      : 'No books match your search',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha:0.5),
                                  ),
                                ),
                                const widgets.SizedBox(height: 8),
                                widgets.Text(
                                  _searchQuery.isEmpty 
                                      ? 'Download some books to see them here' 
                                      : 'Try a different search term',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha:0.4),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : widgets.FadeTransition(
                            opacity: _fadeAnimation,
                            child: widgets.ListView.builder(
                              itemCount: _filteredBooks.length,
                              itemBuilder: (context, index) {
                                return _buildBookCard(_filteredBooks[index]);
                              },
                            ),
                          ),
                  ),
                ],
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