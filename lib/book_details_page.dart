import 'package:flutter/material.dart' as widgets;
import 'database_helper.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'epub_reader_page.dart';

class BookDetailsPage extends widgets.StatefulWidget {
  final Book book;
  const BookDetailsPage({super.key, required this.book});

  @override
  widgets.State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends widgets.State<BookDetailsPage> with widgets.SingleTickerProviderStateMixin {
  late widgets.TabController _tabController;
  bool _downloading = false;
  double _downloadProgress = 0.0;
  bool _isBookDownloaded = false;
  String? _localFilePath;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _tabController = widgets.TabController(length: 3, vsync: this);
    _checkIfBookExists();
  }

  Future<void> _checkIfBookExists() async {
    final book = widget.book;
    String? url = book.epubDownloadUrl ?? book.pdfDownloadUrl ?? book.txtDownloadUrl;
    String? ext;
    if (book.epubDownloadUrl != null) { ext = 'epub'; }
    else if (book.pdfDownloadUrl != null) { ext = 'pdf'; }
    else if (book.txtDownloadUrl != null) { ext = 'txt'; }
    
    if (url != null && ext != null) {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${book.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.$ext';
      final file = File(savePath);
      if (await file.exists()) {
        if (!mounted) return;
        setState(() {
          _isBookDownloaded = true;
          _localFilePath = savePath;
        });
      } else {
      }
    } else {
    }
  }

  Future<void> _openBook() async {
    if (_localFilePath != null) {
      final book = widget.book;
      String? ext;
      if (book.epubDownloadUrl != null) { ext = 'epub'; }
      else if (book.pdfDownloadUrl != null) { ext = 'pdf'; }
      else if (book.txtDownloadUrl != null) { ext = 'txt'; }
      
      if (ext == 'epub') {
        if (!mounted) return;
        widgets.Navigator.push(
          context,
          widgets.MaterialPageRoute(
            builder: (context) => EpubReaderPage(
              filePath: _localFilePath!,
              bookTitle: book.title,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        widgets.ScaffoldMessenger.of(context).showSnackBar(
          widgets.SnackBar(content: widgets.Text('Opening $ext file...')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Download cancelled by leaving the page.');
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _downloadBook() async {
    final book = widget.book;
    String? url = book.epubDownloadUrl ?? book.pdfDownloadUrl ?? book.txtDownloadUrl;
    String? ext;
    if (book.epubDownloadUrl != null) { ext = 'epub'; }
    else if (book.pdfDownloadUrl != null) { ext = 'pdf'; }
    else if (book.txtDownloadUrl != null) { ext = 'txt'; }

    if (url == null) {
      if (!mounted) return;
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        const widgets.SnackBar(content: widgets.Text('No downloadable file available for this book.')),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/${book.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.$ext';
    final file = File(savePath);
    if (await file.exists()) {
      // File already exists, open directly
      if (ext == 'epub') {
        if (!mounted) return;
        widgets.Navigator.push(
          context,
          widgets.MaterialPageRoute(
            builder: (context) => EpubReaderPage(
              filePath: savePath,
              bookTitle: book.title,
            ),
          ),
        );
        return;
      }
      // You can add logic for PDF/TXT if needed
      if (!mounted) return;
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        widgets.SnackBar(content: widgets.Text('Book already downloaded.')),
      );
      return;
    }

    setState(() {
      _downloading = true;
      _downloadProgress = 0.0;
      _cancelToken = CancelToken();
    });

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      setState(() {
        _downloading = false;
        _cancelToken = null;
      });
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        widgets.SnackBar(content: widgets.Text('No internet connection. Please check your network and try again.')),
      );
      return;
    }

    final dio = Dio();
    int retries = 0;
    const maxRetries = 3;
    bool success = false;
    while (retries < maxRetries && !success) {
      try {
        await dio.download(
          url,
          savePath,
          cancelToken: _cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _downloadProgress = received / total;
              });
            }
          },
          options: Options(
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        );
        success = true;
        _cancelToken = null;
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          setState(() {
            _downloading = false;
            _cancelToken = null;
          });
          widgets.ScaffoldMessenger.of(context).showSnackBar(
            const widgets.SnackBar(content: widgets.Text('Download cancelled.')),
          );
          return;
        }
        retries++;
        if (retries >= maxRetries) {
          // Clean up partial file
          if (await file.exists()) await file.delete();
          setState(() {
            _downloading = false;
            _cancelToken = null;
          });
          widgets.ScaffoldMessenger.of(context).showSnackBar(
            widgets.SnackBar(content: widgets.Text('Download failed after $maxRetries attempts: ${e.message ?? e.toString()}')),
          );
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        retries = maxRetries; // Don't retry on unknown errors
        setState(() {
          _downloading = false;
          _cancelToken = null;
        });
        widgets.ScaffoldMessenger.of(context).showSnackBar(
          widgets.SnackBar(content: widgets.Text('Download failed: ${e.toString()}')),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _downloading = false;
      _isBookDownloaded = true;
      _localFilePath = savePath;
      _cancelToken = null;
    });

    // Save mapping from file path to book ID
    final mappingFile = File('${dir.path}/downloaded_books.json');
    Map<String, dynamic> mapping = {};
    if (await mappingFile.exists()) {
      final content = await mappingFile.readAsString();
      if (content.isNotEmpty) {
        mapping = json.decode(content);
      }
    }
    mapping[savePath] = book.id;
    await mappingFile.writeAsString(json.encode(mapping));

    widgets.ScaffoldMessenger.of(context).showSnackBar(
      widgets.SnackBar(content: widgets.Text('Downloaded to $savePath')),
    );

    // Open EPUB with the new reader page
    if (ext == 'epub') {
      try {
        if (await file.exists()) {
          if (!mounted) return;
          widgets.Navigator.push(
            context,
            widgets.MaterialPageRoute(
              builder: (context) => EpubReaderPage(
                filePath: savePath,
                bookTitle: book.title,
              ),
            ),
          );
        } else {
          throw Exception('File does not exist');
        }
      } catch (e) {
        if (!mounted) return;
        widgets.ScaffoldMessenger.of(context).showSnackBar(
          widgets.SnackBar(
            content: widgets.Text('Failed to open EPUB: $e'),
            backgroundColor: widgets.Colors.red,
          ),
        );
      }
    }
  }

  @override
  widgets.Widget build(widgets.BuildContext context) {
    final book = widget.book;
    final theme = widgets.Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return widgets.Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: widgets.AppBar(
        backgroundColor: widgets.Colors.transparent,
        elevation: 0,
        leading: widgets.IconButton(
          icon: widgets.Icon(widgets.Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => widgets.Navigator.of(context).pop(),
        ),
        actions: [
          widgets.IconButton(
            icon: widgets.Icon(widgets.Icons.bookmark_border, color: colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
        iconTheme: widgets.IconThemeData(color: colorScheme.onSurface),
      ),
      body: widgets.Padding(
        padding: const widgets.EdgeInsets.symmetric(horizontal: 24.0),
        child: widgets.Column(
          crossAxisAlignment: widgets.CrossAxisAlignment.stretch,
          children: [
            // Book Cover
            widgets.Center(
              child: widgets.ClipRRect(
                borderRadius: widgets.BorderRadius.circular(12),
                child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                    ? widgets.Image.network(
                        book.coverImageUrl!,
                        width: 180,
                        height: 240,
                        fit: widgets.BoxFit.cover,
                      )
                    : widgets.Container(
                        width: 180,
                        height: 240,
                        color: colorScheme.surfaceContainerHighest,
                        child: widgets.Icon(widgets.Icons.book, size: 64, color: colorScheme.outline),
                      ),
              ),
            ),
            const widgets.SizedBox(height: 24),
            // Book Title
            widgets.Text(
              book.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: widgets.FontWeight.bold),
              textAlign: widgets.TextAlign.center,
            ),
            if (book.authorName != null && book.authorName!.isNotEmpty) ...[
              const widgets.SizedBox(height: 6),
              widgets.Text(
                book.authorName!,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha:0.7), fontWeight: widgets.FontWeight.w500),
                textAlign: widgets.TextAlign.center,
              ),
            ],
            const widgets.SizedBox(height: 16),
            // Book Info Row
            widgets.Row(
              mainAxisAlignment: widgets.MainAxisAlignment.center,
              children: [
                _VerticalDivider(),
                _InfoColumn(label: 'Rating', value: book.rating != null ? '${book.rating!.toStringAsFixed(1)}/5' : '4.9/5'),
                _VerticalDivider(),
                _InfoColumn(label: 'Read', value: '5.3k'),
                _VerticalDivider(),
                _InfoColumn(label: 'Pages', value: book.pages?.toString() ?? '-'),
              ],
            ),
            const widgets.SizedBox(height: 24),
            // Tabs
            widgets.Container(
              padding: const widgets.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: widgets.BoxDecoration(
                color: theme.cardColor,
                borderRadius: widgets.BorderRadius.circular(12),
                boxShadow: [
                  widgets.BoxShadow(
                    color: widgets.Colors.black.withValues(alpha:0.03),
                    blurRadius: 4,
                    offset: const widgets.Offset(0, 2),
                  ),
                ],
              ),
              child: widgets.TabBar(
                controller: _tabController,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.primary,
                indicator: widgets.BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: widgets.BorderRadius.circular(8),
                ),
                dividerColor: widgets.Colors.transparent,
                indicatorSize: widgets.TabBarIndicatorSize.tab,
                overlayColor: widgets.WidgetStateProperty.all(widgets.Colors.transparent),
                tabs: const [
                  widgets.Tab(child: widgets.Align(alignment: widgets.Alignment.center, child: widgets.Text('Description'))),
                  widgets.Tab(child: widgets.Align(alignment: widgets.Alignment.center, child: widgets.Text('Reviews'))),
                  widgets.Tab(child: widgets.Align(alignment: widgets.Alignment.center, child: widgets.Text('Instruction'))),
                ],
              ),
            ),
            widgets.Divider(height: 18, thickness: 1, color: colorScheme.outline.withValues(alpha:0.08)),
            // Tab Content
            widgets.Expanded(
              child: widgets.Container(
                decoration: widgets.BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: widgets.BorderRadius.circular(12),
                ),
                child: widgets.TabBarView(
                  controller: _tabController,
                  children: [
                    widgets.Padding(
                      padding: const widgets.EdgeInsets.all(16.0),
                      child: widgets.Text(
                        book.description ?? 'No description available.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const widgets.Center(child: widgets.Text('No reviews yet.')),
                    const widgets.Center(child: widgets.Text('No instructions available.')),
                  ],
                ),
              ),
            ),
            const widgets.SizedBox(height: 18),
            // Buttons
            widgets.Row(
              children: [
                widgets.Expanded(
                  child: widgets.OutlinedButton(
                    onPressed: () {},
                    style: widgets.OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: widgets.BorderSide(color: colorScheme.primary),
                      shape: widgets.RoundedRectangleBorder(borderRadius: widgets.BorderRadius.circular(8)),
                      padding: const widgets.EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const widgets.Text('Read Sample', style: widgets.TextStyle(fontSize: 16)),
                  ),
                ),
                const widgets.SizedBox(width: 16),
                widgets.Expanded(
                  child: widgets.ElevatedButton(
                    onPressed: _downloading ? null : (_isBookDownloaded ? _openBook : _downloadBook),
                    style: widgets.ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: widgets.RoundedRectangleBorder(borderRadius: widgets.BorderRadius.circular(8)),
                      padding: const widgets.EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _downloading
                        ? widgets.SizedBox(
                            height: 18,
                            width: 18,
                            child: widgets.CircularProgressIndicator(
                              value: _downloadProgress,
                              strokeWidth: 2.5,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : widgets.Text(_isBookDownloaded ? 'Read' : 'Download', style: const widgets.TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            if (_downloading) ...[
              const widgets.SizedBox(height: 12),
              widgets.LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: widgets.AlwaysStoppedAnimation<widgets.Color>(colorScheme.primary),
              ),
              const widgets.SizedBox(height: 8),
              widgets.TextButton.icon(
                onPressed: () {
                  _cancelToken?.cancel('Download cancelled by user.');
                  setState(() {
                    _downloading = false;
                  });
                },
                icon: const widgets.Icon(widgets.Icons.cancel, color: widgets.Colors.red),
                label: const widgets.Text('Cancel Download', style: widgets.TextStyle(color: widgets.Colors.red)),
              ),
            ],
            const widgets.SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends widgets.StatelessWidget {
  final String label;
  final String value;
  const _InfoColumn({required this.label, required this.value});

  @override
  widgets.Widget build(widgets.BuildContext context) {
    final theme = widgets.Theme.of(context);
    final colorScheme = theme.colorScheme;
    return widgets.Column(
      children: [
        widgets.Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: widgets.FontWeight.bold),
        ),
        const widgets.SizedBox(height: 4),
        widgets.Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha:0.7)),
        ),
      ],
    );
  }
}

class _VerticalDivider extends widgets.StatelessWidget {
  @override
  widgets.Widget build(widgets.BuildContext context) {
    final colorScheme = widgets.Theme.of(context).colorScheme;
    return widgets.Container(
      margin: const widgets.EdgeInsets.symmetric(horizontal: 12),
      height: 32,
      width: 1.5,
      color: colorScheme.outline.withValues(alpha:0.15),
    );
  }
} 