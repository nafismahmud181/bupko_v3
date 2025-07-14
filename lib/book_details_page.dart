import 'package:flutter/material.dart' as widgets;
import 'database_helper.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:epub_view/epub_view.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (book.epubDownloadUrl != null) ext = 'epub';
    else if (book.pdfDownloadUrl != null) ext = 'pdf';
    else if (book.txtDownloadUrl != null) ext = 'txt';
    
    if (url != null && ext != null) {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${book.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.${ext ?? 'file'}';
      final file = File(savePath);
      print('Checking if book exists: $savePath');
      print('Book title: ${book.title}');
      print('Extension: $ext');
      if (await file.exists()) {
        print('Book exists! Setting _isBookDownloaded to true');
        setState(() {
          _isBookDownloaded = true;
          _localFilePath = savePath;
        });
      } else {
        print('Book does not exist');
      }
    } else {
      print('No download URL or extension found');
    }
  }

  Future<void> _openBook() async {
    if (_localFilePath != null) {
      final book = widget.book;
      String? ext;
      if (book.epubDownloadUrl != null) ext = 'epub';
      else if (book.pdfDownloadUrl != null) ext = 'pdf';
      else if (book.txtDownloadUrl != null) ext = 'txt';
      
      if (ext == 'epub') {
        widgets.Navigator.push(
          context,
          widgets.MaterialPageRoute(
            builder: (context) => EpubReaderScreen(
              filePath: _localFilePath!,
              bookTitle: book.title,
            ),
          ),
        );
      } else {
        widgets.ScaffoldMessenger.of(context).showSnackBar(
          widgets.SnackBar(content: widgets.Text('Opening $ext file...')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _downloadBook() async {
    final book = widget.book;
    String? url = book.epubDownloadUrl ?? book.pdfDownloadUrl ?? book.txtDownloadUrl;
    String? ext;
    if (book.epubDownloadUrl != null) ext = 'epub';
    else if (book.pdfDownloadUrl != null) ext = 'pdf';
    else if (book.txtDownloadUrl != null) ext = 'txt';
    
    if (url == null) {
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        const widgets.SnackBar(content: widgets.Text('No downloadable file available for this book.')),
      );
      return;
    }
    
    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/${book.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.${ext ?? 'file'}';
    final file = File(savePath);
    if (await file.exists()) {
      // File already exists, open directly
      if (ext == 'epub') {
        widgets.Navigator.push(
          context,
          widgets.MaterialPageRoute(
            builder: (context) => EpubReaderScreen(
              filePath: savePath,
              bookTitle: book.title,
            ),
          ),
        );
        return;
      }
      // You can add logic for PDF/TXT if needed
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        widgets.SnackBar(content: widgets.Text('Book already downloaded.')),
      );
      return;
    }
    
    setState(() {
      _downloading = true;
      _downloadProgress = 0.0;
    });
    
    try {
      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );
      
      setState(() {
        _downloading = false;
        _isBookDownloaded = true;
        _localFilePath = savePath;
      });
      
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        widgets.SnackBar(content: widgets.Text('Downloaded to $savePath')),
      );
      
      // Open EPUB with epub_view
      if (ext == 'epub') {
        try {
          if (await file.exists()) {
            widgets.Navigator.push(
              context,
              widgets.MaterialPageRoute(
                builder: (context) => EpubReaderScreen(
                  filePath: savePath,
                  bookTitle: book.title,
                ),
              ),
            );
          } else {
            throw Exception('File does not exist');
          }
        } catch (e) {
          print('Error opening EPUB: $e');
          widgets.ScaffoldMessenger.of(context).showSnackBar(
            widgets.SnackBar(
              content: widgets.Text('Failed to open EPUB: $e'),
              backgroundColor: widgets.Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _downloading = false;
      });
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        widgets.SnackBar(content: widgets.Text('Download failed: $e')),
      );
    }
  }

  @override
  widgets.Widget build(widgets.BuildContext context) {
    final book = widget.book;
    final theme = widgets.Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return widgets.Scaffold(
      backgroundColor: colorScheme.background,
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
                        color: colorScheme.surfaceVariant,
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
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7), fontWeight: widgets.FontWeight.w500),
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
                    color: widgets.Colors.black.withOpacity(0.03),
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
                overlayColor: widgets.MaterialStateProperty.all(widgets.Colors.transparent),
                tabs: const [
                  widgets.Tab(child: widgets.Align(alignment: widgets.Alignment.center, child: widgets.Text('Description'))),
                  widgets.Tab(child: widgets.Align(alignment: widgets.Alignment.center, child: widgets.Text('Reviews'))),
                  widgets.Tab(child: widgets.Align(alignment: widgets.Alignment.center, child: widgets.Text('Instruction'))),
                ],
              ),
            ),
            widgets.Divider(height: 18, thickness: 1, color: colorScheme.outline.withOpacity(0.08)),
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
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: widgets.AlwaysStoppedAnimation<widgets.Color>(colorScheme.primary),
              ),
            ],
            const widgets.SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

// Custom EPUB Reader Screen using epub_view
class EpubReaderScreen extends widgets.StatefulWidget {
  final String filePath;
  final String bookTitle;
  
  const EpubReaderScreen({
    widgets.Key? key,
    required this.filePath,
    required this.bookTitle,
  }) : super(key: key);

  @override
  widgets.State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends widgets.State<EpubReaderScreen> {
  late EpubController _epubController;
  bool _isLoading = true;
  bool _showSettings = false;
  
  // Font settings
  double _fontSize = 16.0;
  String _fontFamily = 'serif';
  final List<String> _fontFamilies = [
    'serif',
    'sans-serif',
    'monospace',
    'Georgia',
    'Times New Roman',
    'Arial',
    'Helvetica',
    'Courier New',
  ];

  @override
  void initState() {
    super.initState();
    _loadFontSettings();
    _initEpubController();
  }

  Future<void> _loadFontSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
      _fontFamily = prefs.getString('fontFamily') ?? 'serif';
    });
  }

  Future<void> _saveFontSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setString('fontFamily', _fontFamily);
  }

  void _initEpubController() async {
    try {
      _epubController = EpubController(
        document: EpubDocument.openFile(File(widget.filePath)),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing EPUB controller: $e');
      setState(() {
        _isLoading = false;
      });
      widgets.ScaffoldMessenger.of(context).showSnackBar(
        widgets.SnackBar(content: widgets.Text('Failed to open EPUB: $e')),
      );
    }
  }

  @override
  void dispose() {
    _epubController.dispose();
    super.dispose();
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  void _updateFontSize(double size) {
    setState(() {
      _fontSize = size;
    });
    _saveFontSettings();
  }

  void _updateFontFamily(String family) {
    setState(() {
      _fontFamily = family;
    });
    _saveFontSettings();
  }

  @override
  widgets.Widget build(widgets.BuildContext context) {
    final theme = widgets.Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return widgets.Scaffold(
      backgroundColor: colorScheme.background,
      appBar: widgets.AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 1,
        title: _isLoading
            ? widgets.Text(widget.bookTitle)
            : EpubViewActualChapter(
                controller: _epubController,
                builder: (chapterValue) => widgets.Text(
                  chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ?? 
                  widget.bookTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
        leading: widgets.IconButton(
          icon: widgets.Icon(widgets.Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => widgets.Navigator.of(context).pop(),
        ),
        actions: [
          widgets.IconButton(
            icon: widgets.Icon(widgets.Icons.bookmark_border, color: colorScheme.onSurface),
            onPressed: () {},
          ),
          widgets.IconButton(
            icon: widgets.Icon(widgets.Icons.settings, color: colorScheme.onSurface),
            onPressed: _toggleSettings,
          ),
        ],
      ),
      body: widgets.Stack(
        children: [
          _isLoading
              ? const widgets.Center(child: widgets.CircularProgressIndicator())
              : EpubView(
                  controller: _epubController,
                  onExternalLinkPressed: (href) {
                    print('External link pressed: $href');
                  },
                  onDocumentLoaded: (document) {
                    print('Document loaded: ${document.Title}');
                  },
                  onChapterChanged: (chapter) {
                    // print('Chapter changed: ${chapter?.Title}');
                  },
                  onDocumentError: (error) {
                    print('Document error: $error');
                    widgets.ScaffoldMessenger.of(context).showSnackBar(
                      widgets.SnackBar(content: widgets.Text('Error loading document: $error')),
                    );
                  },
                ),
          if (_showSettings)
            widgets.Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: widgets.Container(
                padding: const widgets.EdgeInsets.all(16),
                decoration: widgets.BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    widgets.BoxShadow(
                      color: widgets.Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const widgets.Offset(0, 2),
                    ),
                  ],
                ),
                child: widgets.Column(
                  crossAxisAlignment: widgets.CrossAxisAlignment.start,
                  mainAxisSize: widgets.MainAxisSize.min,
                  children: [
                    widgets.Row(
                      mainAxisAlignment: widgets.MainAxisAlignment.spaceBetween,
                      children: [
                        widgets.Text(
                          'Reading Settings',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: widgets.FontWeight.bold,
                          ),
                        ),
                        widgets.IconButton(
                          icon: widgets.Icon(widgets.Icons.close),
                          onPressed: _toggleSettings,
                        ),
                      ],
                    ),
                    const widgets.SizedBox(height: 16),
                    // Font Size Control
                    widgets.Text(
                      'Font Size: ${_fontSize.round()}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    widgets.Slider(
                      value: _fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      label: _fontSize.round().toString(),
                      onChanged: _updateFontSize,
                    ),
                    const widgets.SizedBox(height: 16),
                    // Font Family Control
                    widgets.Text(
                      'Font Family',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const widgets.SizedBox(height: 8),
                    widgets.DropdownButtonFormField<String>(
                      value: _fontFamily,
                      decoration: widgets.InputDecoration(
                        border: widgets.OutlineInputBorder(
                          borderRadius: widgets.BorderRadius.circular(8),
                        ),
                        contentPadding: const widgets.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _fontFamilies.map((font) {
                        return widgets.DropdownMenuItem(
                          value: font,
                          child: widgets.Text(
                            font,
                            style: widgets.TextStyle(fontFamily: font),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _updateFontFamily(value);
                        }
                      },
                    ),
                    const widgets.SizedBox(height: 16),
                    // Preview Text
                    widgets.Container(
                      padding: const widgets.EdgeInsets.all(12),
                      decoration: widgets.BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: widgets.BorderRadius.circular(8),
                      ),
                      child: widgets.Text(
                        'Preview: The quick brown fox jumps over the lazy dog.',
                        style: widgets.TextStyle(
                          fontSize: _fontSize,
                          fontFamily: _fontFamily,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
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
      color: colorScheme.outline.withOpacity(0.15),
    );
  }
}