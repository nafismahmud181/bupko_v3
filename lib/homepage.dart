import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'search_page.dart';
import 'book_upload_form_page.dart';
import 'book_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'main.dart';
import 'category_page.dart';
import 'setting_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<CategoryWithBooks>>? _booksFuture;

  @override
  void initState() {
    super.initState();
    _loadBooks();
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Ebook Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
            tooltip: 'Search Books',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDatabase,
            tooltip: 'Refresh Database',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.email ?? 'Guest'),
              accountEmail: user != null ? Text(user.email ?? '') : null,
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person, size: 36),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            ListTile(
              leading: Icon(user != null ? Icons.logout : Icons.login),
              title: Text(user != null ? 'Logout' : 'Login'),
              onTap: () async {
                Navigator.pop(context); // Close the drawer
                if (user != null) {
                  await FirebaseAuth.instance.signOut();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Dark Mode'),
              trailing: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, mode, _) {
                  return Switch(
                    value: mode == ThemeMode.dark,
                    onChanged: (val) {
                      themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<CategoryWithBooks>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading books: 24{snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No books found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final categoryWithBooks = snapshot.data![index];
              return CategorySection(categoryWithBooks: categoryWithBooks);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookUploadFormPage()),
          );
        },
        child: const Icon(Icons.upload_file),
        tooltip: 'Upload Book',
      ),
    );
  }
}

class CategorySection extends StatelessWidget {
  final CategoryWithBooks categoryWithBooks;

  const CategorySection({
    super.key,
    required this.categoryWithBooks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            categoryWithBooks.category.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoryWithBooks.books.length,
            itemBuilder: (context, index) {
              final book = categoryWithBooks.books[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailsPage(book: book),
                    ),
                  );
                },
                child: BookCard(book: book),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                    ? Image.network(
                        book.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.book,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.book,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            // Book Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.authorName ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 