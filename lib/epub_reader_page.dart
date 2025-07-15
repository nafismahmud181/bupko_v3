import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

class EpubReaderPage extends StatefulWidget {
  final String filePath;
  final String bookTitle;
  
  const EpubReaderPage({
    super.key,
    required this.filePath,
    required this.bookTitle,
  });

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  late EpubController _epubController;
  bool _isLoading = true;
  bool _showSettings = false;
  Timer? _saveTimer;
  
  // Reading settings
  double _fontSize = 16.0;
  String _fontFamily = 'serif';
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;
  double _lineHeight = 1.5;
  double _textAlign = 0; // 0 = left, 1 = center, 2 = justify
  
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

  final List<Color> _backgroundColors = [
    Colors.white,
    const Color(0xFFF5F5DC), // Beige
    const Color(0xFF2E2E2E), // Dark
    const Color(0xFF1A1A1A), // Black
  ];

  final List<String> _backgroundNames = [
    'White',
    'Sepia',
    'Dark',
    'Black',
  ];

  final List<String> _textAlignNames = [
    'Left',
    'Center',
    'Justify',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
      _fontFamily = prefs.getString('fontFamily') ?? 'serif';
      _lineHeight = prefs.getDouble('lineHeight') ?? 1.5;
      _textAlign = prefs.getDouble('textAlign') ?? 0;
      
      // Load background color
      final bgColorIndex = prefs.getInt('backgroundColorIndex') ?? 0;
      _backgroundColor = _backgroundColors[bgColorIndex];
      
      // Set text color based on background - FIXED
      _textColor = _getTextColorForBackground(_backgroundColor);
    });
    
    _initEpubController();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setString('fontFamily', _fontFamily);
    await prefs.setDouble('lineHeight', _lineHeight);
    await prefs.setDouble('textAlign', _textAlign);
    await prefs.setInt('backgroundColorIndex', _backgroundColors.indexOf(_backgroundColor));
  }

  // Debounced save to prevent excessive writes
  void _debouncedSaveSettings() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveSettings();
    });
  }

  // FIXED: Better text color logic
  Color _getTextColorForBackground(Color bg) {
    // White and Sepia backgrounds get black text
    if (bg == Colors.white || bg == const Color(0xFFF5F5DC)) {
      return Colors.black;
    } 
    // Dark and Black backgrounds get white text
    else if (bg == const Color(0xFF2E2E2E) || bg == const Color(0xFF1A1A1A)) {
      return Colors.white;
    }
    // Default fallback
    else {
      return Colors.black;
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open EPUB: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
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
    _debouncedSaveSettings();
  }

  void _updateFontFamily(String family) {
    setState(() {
      _fontFamily = family;
    });
    _saveSettings(); // Save immediately for dropdown changes
  }

  void _updateLineHeight(double height) {
    setState(() {
      _lineHeight = height;
    });
    _debouncedSaveSettings();
  }

  void _updateTextAlign(double align) {
    setState(() {
      _textAlign = align;
    });
    _saveSettings(); // Save immediately for button changes
  }

  void _updateBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
      _textColor = _getTextColorForBackground(color);
    });
    _saveSettings(); // Save immediately for theme changes
  }

  void _showTableOfContents() {
    // TODO: Implement table of contents
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Table of Contents - Coming Soon')),
    );
  }

  void _showBookmarks() {
    // TODO: Implement bookmarks
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmarks - Coming Soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 1,
        title: _isLoading
            ? Text(widget.bookTitle, style: TextStyle(color: _textColor))
            : EpubViewActualChapter(
                controller: _epubController,
                builder: (chapterValue) => Text(
                  chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ?? 
                  widget.bookTitle,
                  style: theme.textTheme.titleMedium?.copyWith(color: _textColor),
                ),
              ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.list, color: _textColor),
            onPressed: _showTableOfContents,
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border, color: _textColor),
            onPressed: _showBookmarks,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: _textColor),
            onPressed: _toggleSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator(color: _textColor))
              : Container(
                  color: _backgroundColor,
                  child: EpubView(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error loading document: $error')),
                      );
                    },
                    // IMPROVED: Apply custom styling through the builders
                    builders: EpubViewBuilders<DefaultBuilderOptions>(
                      options: DefaultBuilderOptions(
                        textStyle: TextStyle(
                          fontSize: _fontSize,
                          fontFamily: _fontFamily,
                          color: _textColor,
                          height: _lineHeight,
                        ),
                      ),
                      chapterDividerBuilder: (context) => Container(
                        height: 1,
                        color: _textColor.withOpacity(0.2),
                      ),
                      loaderBuilder: (context) => Center(
                        child: CircularProgressIndicator(color: _textColor),
                      ),
                    ),
                  ),
                ),
          if (_showSettings)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reading Settings',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _toggleSettings,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Font Size Control
                      Text(
                        'Font Size: ${_fontSize.round()}px',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Slider(
                        value: _fontSize,
                        min: 12.0,
                        max: 28.0,
                        divisions: 16,
                        label: '${_fontSize.round()}px',
                        onChanged: _updateFontSize,
                      ),
                      const SizedBox(height: 16),
                      
                      // Font Family Control
                      Text(
                        'Font Family',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _fontFamily,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _fontFamilies.map((font) {
                          return DropdownMenuItem(
                            value: font,
                            child: Text(
                              font,
                              style: TextStyle(fontFamily: font),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _updateFontFamily(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Line Height Control
                      Text(
                        'Line Height: ${_lineHeight.toStringAsFixed(1)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Slider(
                        value: _lineHeight,
                        min: 1.0,
                        max: 2.5,
                        divisions: 15,
                        label: _lineHeight.toStringAsFixed(1),
                        onChanged: _updateLineHeight,
                      ),
                      const SizedBox(height: 16),
                      
                      // Text Alignment Control
                      Text(
                        'Text Alignment',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (int i = 0; i < _textAlignNames.length; i++)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: i < _textAlignNames.length - 1 ? 8 : 0),
                                child: ChoiceChip(
                                  label: Text(_textAlignNames[i]),
                                  selected: _textAlign == i,
                                  onSelected: (selected) {
                                    if (selected) {
                                      _updateTextAlign(i.toDouble());
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Background Color Control
                      Text(
                        'Background Theme',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _backgroundColors.length,
                          itemBuilder: (context, index) {
                            final color = _backgroundColors[index];
                            final name = _backgroundNames[index];
                            final isSelected = _backgroundColor == color;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => _updateBackgroundColor(color),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: color,
                                        border: Border.all(
                                          color: isSelected ? colorScheme.primary : Colors.grey,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? colorScheme.primary : Colors.grey,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Preview Text
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Preview: The quick brown fox jumps over the lazy dog. This is how your text will appear with the current settings.',
                          style: TextStyle(
                            fontSize: _fontSize,
                            fontFamily: _fontFamily,
                            color: _textColor,
                            height: _lineHeight,
                          ),
                          textAlign: _textAlign == 0 ? TextAlign.left : 
                                   _textAlign == 1 ? TextAlign.center : 
                                   TextAlign.justify,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Current theme info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.palette, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current theme: ${_backgroundNames[_backgroundColors.indexOf(_backgroundColor)]} background with ${_textColor == Colors.black ? 'black' : 'white'} text',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Note about styling limitations
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.amber[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Note: Some styling options may have limited effect on EPUB content depending on the book\'s original formatting.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}