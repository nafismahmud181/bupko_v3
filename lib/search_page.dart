import 'dart:async';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'book_details_page.dart'; // Added import for BookDetailsPage

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  List<Book> _results = [];
  bool _loading = false;
  String _lastQuery = '';
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(_controller.text);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _lastQuery = query;
    });
    final db = DatabaseHelper();
    final books = await db.searchBooks(query, limit: 50); // Limit results
    setState(() {
      _results = books;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          // autofocus: true, // Removed autofocus to prevent keyboard flicker
          decoration: const InputDecoration(
            hintText: 'Search books by title or author...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _search('');
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty && _lastQuery.isNotEmpty
              ? const Center(child: Text('No results found.'))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final book = _results[index];
                    return ListTile(
                      leading: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                          ? Image.network(book.coverImageUrl!, width: 40, height: 60, fit: BoxFit.cover)
                          : const Icon(Icons.book, size: 40),
                      title: Text(book.title),
                      subtitle: Text(book.authorName ?? ''),
                      onTap: () async {
                        FocusScope.of(context).unfocus(); // Hide the keyboard
                        await Future.delayed(const Duration(milliseconds: 150)); // Wait 150ms
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailsPage(book: book),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
} 