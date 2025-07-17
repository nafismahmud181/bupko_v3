import 'package:flutter/material.dart' as widgets;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'epub_reader_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_details_page.dart'; // Added import for BookDetailsPage
import 'database_helper.dart'; // Import Book model

class LibraryPage extends widgets.StatefulWidget {
  const LibraryPage({super.key});

  @override
  widgets.State<LibraryPage> createState() => _LibraryPageState();
}

class FirestoreBook {
  final String id;
  final String title;
  final String? authorName;
  final String? coverImageUrl;
  final String fileType;
  final String? epubDownloadUrl;
  final String? pdfDownloadUrl;
  final String? txtDownloadUrl;

  FirestoreBook({
    required this.id,
    required this.title,
    this.authorName,
    this.coverImageUrl,
    required this.fileType,
    this.epubDownloadUrl,
    this.pdfDownloadUrl,
    this.txtDownloadUrl,
  });

  factory FirestoreBook.fromMap(Map<String, dynamic> map) {
    return FirestoreBook(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      authorName: map['authorName'],
      coverImageUrl: map['coverImageUrl'],
      fileType: map['fileType'] ?? '',
      epubDownloadUrl: map['epubDownloadUrl'],
      pdfDownloadUrl: map['pdfDownloadUrl'],
      txtDownloadUrl: map['txtDownloadUrl'],
    );
  }
}

class _LibraryPageState extends widgets.State<LibraryPage> with widgets.SingleTickerProviderStateMixin, widgets.WidgetsBindingObserver {
  List<FirestoreBook> _firestoreBooks = [];
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
    _loadFirestoreBooks();
  }

  @override
  void dispose() {
    widgets.WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFirestoreBooks() async {
    setState(() {
      _isLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _firestoreBooks = [];
        _isLoading = false;
      });
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('downloaded_books')
        .get();
    final books = snapshot.docs.map((doc) => FirestoreBook.fromMap(doc.data())).toList();
    setState(() {
      _firestoreBooks = books;
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<bool> _localFileExists(FirestoreBook book) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${book.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.${book.fileType}';
    final file = File('${dir.path}/$fileName');
    return file.exists();
  }

  Future<void> _openOrDownloadBook(FirestoreBook book) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${book.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.${book.fileType}';
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) {
      // Open the book (epub/pdf/txt)
      if (book.fileType == 'epub') {
        if (!mounted) return;
        widgets.Navigator.push(
          context,
          widgets.MaterialPageRoute(
            builder: (context) => EpubReaderPage(
              filePath: file.path,
              bookTitle: book.title,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        widgets.ScaffoldMessenger.of(context).showSnackBar(
          widgets.SnackBar(content: widgets.Text('Opening ${book.fileType.toUpperCase()} file...')),
        );
      }
    } else {
      // Download the book again
      String? url = book.epubDownloadUrl ?? book.pdfDownloadUrl ?? book.txtDownloadUrl;
      if (url == null) {
        if (!mounted) return;
        widgets.ScaffoldMessenger.of(context).showSnackBar(
          widgets.SnackBar(content: widgets.Text('No download URL available for this book.')),
        );
        return;
      }
      if (!mounted) return;
      widgets.Navigator.push(
        context,
        widgets.MaterialPageRoute(
          builder: (context) => BookDetailsPage(book: Book(
            id: int.tryParse(book.id) ?? 0,
            title: book.title,
            authorName: book.authorName,
            coverImageUrl: book.coverImageUrl,
            epubDownloadUrl: book.epubDownloadUrl,
            pdfDownloadUrl: book.pdfDownloadUrl,
            txtDownloadUrl: book.txtDownloadUrl,
          )),
        ),
      ).then((_) => _loadFirestoreBooks());
    }
  }

  List<FirestoreBook> get _filteredBooks {
    if (_searchQuery.isEmpty) return _firestoreBooks;
    return _firestoreBooks.where((book) =>
        book.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
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

  Future<void> _deleteBook(FirestoreBook book) async {
    // Delete local file if exists
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${book.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.${book.fileType}';
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
    // Delete from Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('downloaded_books')
        .doc(book.id)
        .delete();
    }
  }

  void _showDeleteDialog(FirestoreBook book) {
    widgets.showDialog(
      context: context,
      builder: (context) => widgets.AlertDialog(
        title: const widgets.Text('Delete Book'),
        content: widgets.Text('Are you sure you want to delete "${book.title}"? This will remove the book from your device and your library.'),
        actions: [
          widgets.TextButton(
            onPressed: () => widgets.Navigator.of(context).pop(),
            child: const widgets.Text('Cancel'),
          ),
          widgets.TextButton(
            onPressed: () async {
              widgets.Navigator.of(context).pop();
              await _deleteBook(book);
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

  widgets.Widget _buildBookCard(FirestoreBook book) {
    final theme = widgets.Theme.of(context);
    final colorScheme = theme.colorScheme;
    return widgets.FutureBuilder<bool>(
      future: _localFileExists(book),
      builder: (context, snapshot) {
        final exists = snapshot.data ?? false;
        return widgets.Dismissible(
          key: widgets.Key('book_${book.id}'),
          direction: widgets.DismissDirection.endToStart,
          background: widgets.Container(
            alignment: widgets.Alignment.centerRight,
            padding: const widgets.EdgeInsets.symmetric(horizontal: 24),
            color: widgets.Colors.red,
            child: const widgets.Icon(widgets.Icons.delete, color: widgets.Colors.white, size: 32),
          ),
          confirmDismiss: (direction) async {
            bool? confirm = await widgets.showDialog<bool>(
              context: context,
              builder: (context) => widgets.AlertDialog(
                title: const widgets.Text('Delete Book'),
                content: widgets.Text('Are you sure you want to delete "${book.title}"? This will remove the book from your device and your library.'),
                actions: [
                  widgets.TextButton(
                    onPressed: () => widgets.Navigator.of(context).pop(false),
                    child: const widgets.Text('Cancel'),
                  ),
                  widgets.TextButton(
                    onPressed: () => widgets.Navigator.of(context).pop(true),
                    style: widgets.TextButton.styleFrom(
                      foregroundColor: widgets.Colors.red,
                    ),
                    child: const widgets.Text('Delete'),
                  ),
                ],
              ),
            );
            return confirm == true;
          },
          onDismissed: (direction) async {
            await _deleteBook(book);
          },
          child: widgets.Card(
            margin: const widgets.EdgeInsets.only(bottom: 16),
            elevation: 0,
            shape: widgets.RoundedRectangleBorder(
              borderRadius: widgets.BorderRadius.circular(16),
              side: widgets.BorderSide(
                color: colorScheme.outline.withValues(alpha:0.1),
                width: 1,
              ),
            ),
            child: widgets.Padding(
              padding: const widgets.EdgeInsets.all(16),
              child: widgets.Row(
                crossAxisAlignment: widgets.CrossAxisAlignment.start,
                children: [
                  book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                      ? widgets.ClipRRect(
                          borderRadius: widgets.BorderRadius.circular(8),
                          child: widgets.Image.network(
                            book.coverImageUrl!,
                            width: 50,
                            height: 70,
                            fit: widgets.BoxFit.cover,
                          ),
                        )
                      : widgets.Container(
                          width: 50,
                          height: 70,
                          decoration: widgets.BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: widgets.BorderRadius.circular(8),
                          ),
                          child: const widgets.Icon(widgets.Icons.book, size: 32),
                        ),
                  const widgets.SizedBox(width: 16),
                  widgets.Expanded(
                    child: widgets.Column(
                      crossAxisAlignment: widgets.CrossAxisAlignment.start,
                      children: [
                        widgets.Text(
                          book.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: widgets.FontWeight.bold),
                          maxLines: 2,
                          overflow: widgets.TextOverflow.ellipsis,
                        ),
                        if (book.authorName != null && book.authorName!.isNotEmpty)
                          widgets.Text(
                            book.authorName!,
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha:0.7)),
                            maxLines: 1,
                            overflow: widgets.TextOverflow.ellipsis,
                          ),
                        const widgets.SizedBox(height: 8),
                        widgets.Row(
                          children: [
                            widgets.ElevatedButton(
                              onPressed: () => _openOrDownloadBook(book),
                              style: widgets.ElevatedButton.styleFrom(
                                backgroundColor: exists ? colorScheme.primary : widgets.Colors.red,
                                foregroundColor: widgets.Colors.white,
                                padding: const widgets.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                shape: widgets.RoundedRectangleBorder(
                                  borderRadius: widgets.BorderRadius.circular(8),
                                ),
                              ),
                              child: widgets.Text(exists ? 'Read' : 'Download'),
                            ),
                            const widgets.SizedBox(width: 12),
                            widgets.IconButton(
                              icon: const widgets.Icon(widgets.Icons.delete_outline, color: widgets.Colors.red),
                              onPressed: () => _showDeleteDialog(book),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(widgets.AppLifecycleState state) {
    if (state == widgets.AppLifecycleState.resumed) {
      _loadFirestoreBooks();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _firestoreBooks = [];
      });
    } else {
      _loadFirestoreBooks();
    }
  }

  @override
  widgets.Widget build(widgets.BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const widgets.Center(child: widgets.Text('Not logged in.'));
    }
    return widgets.Scaffold(
      appBar: widgets.AppBar(
        title: const widgets.Text('Your Library'),
      ),
      body: widgets.StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('downloaded_books')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == widgets.ConnectionState.waiting) {
            return const widgets.Center(child: widgets.CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const widgets.Center(child: widgets.Text('No books found in your library.'));
          }
          final books = snapshot.data!.docs
              .map((doc) => FirestoreBook.fromMap(doc.data() as Map<String, dynamic>))
              .where((book) => _searchQuery.isEmpty || book.title.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          return widgets.FadeTransition(
            opacity: _fadeAnimation,
            child: widgets.ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                return _buildBookCard(books[index]);
              },
            ),
          );
        },
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