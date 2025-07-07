import 'package:flutter/material.dart';

class BookUploadFormPage extends StatefulWidget {
  const BookUploadFormPage({super.key});

  @override
  State<BookUploadFormPage> createState() => _BookUploadFormPageState();
}

class _BookUploadFormPageState extends State<BookUploadFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _publicationYearController = TextEditingController();
  final TextEditingController _pagesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _coverImageUrlController = TextEditingController();
  final TextEditingController _epubUrlController = TextEditingController();
  final TextEditingController _pdfUrlController = TextEditingController();
  final TextEditingController _txtUrlController = TextEditingController();

  String? _selectedCategory;
  String? _selectedLanguage;

  // Dummy data for dropdowns (replace with real data later)
  final List<String> _categories = [
    'Fiction', 'Non-fiction', 'Science', 'History', 'Biography', 'Other'
  ];
  final List<String> _languages = [
    'English', 'Spanish', 'French', 'German', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Book'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter the book title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Subtitle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter the author name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                items: _languages.map((lang) => DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                )).toList(),
                onChanged: (val) => setState(() => _selectedLanguage = val),
                decoration: const InputDecoration(
                  labelText: 'Language',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Please select a language' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _publicationYearController,
                decoration: const InputDecoration(
                  labelText: 'Publication Year',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pagesController,
                decoration: const InputDecoration(
                  labelText: 'Pages',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coverImageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Cover Image URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _epubUrlController,
                decoration: const InputDecoration(
                  labelText: 'EPUB Download URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pdfUrlController,
                decoration: const InputDecoration(
                  labelText: 'PDF Download URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _txtUrlController,
                decoration: const InputDecoration(
                  labelText: 'TXT Download URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {}, // No functionality yet
                child: const Text('Upload Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _authorController.dispose();
    _publicationYearController.dispose();
    _pagesController.dispose();
    _descriptionController.dispose();
    _coverImageUrlController.dispose();
    _epubUrlController.dispose();
    _pdfUrlController.dispose();
    _txtUrlController.dispose();
    super.dispose();
  }
} 