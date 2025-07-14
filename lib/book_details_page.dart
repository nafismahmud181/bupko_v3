import 'package:flutter/material.dart';
import 'database_helper.dart';

class BookDetailsPage extends StatefulWidget {
  final Book book;
  const BookDetailsPage({super.key, required this.book});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border, color: colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book Cover
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                    ? Image.network(
                        book.coverImageUrl!,
                        width: 180,
                        height: 240,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 180,
                        height: 240,
                        color: colorScheme.surfaceVariant,
                        child: Icon(Icons.book, size: 64, color: colorScheme.outline),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // Book Title
            Text(
              book.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (book.authorName != null && book.authorName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                book.authorName!,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            // Book Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _VerticalDivider(),
                _InfoColumn(label: 'Rating', value: book.rating != null ? '${book.rating!.toStringAsFixed(1)}/5' : '4.9/5'),
                _VerticalDivider(),
                _InfoColumn(label: 'Read', value: '5.3k'),
                _VerticalDivider(),
                _InfoColumn(label: 'Pages', value: book.pages?.toString() ?? '-'),
              ],
            ),
            const SizedBox(height: 24),
            // Tabs
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.primary,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                tabs: const [
                  Tab(child: Align(alignment: Alignment.center, child: Text('Description'))),
                  Tab(child: Align(alignment: Alignment.center, child: Text('Reviews'))),
                  Tab(child: Align(alignment: Alignment.center, child: Text('Instruction'))),
                ],
              ),
            ),
            Divider(height: 18, thickness: 1, color: colorScheme.outline.withOpacity(0.08)),
            // Tab Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        book.description ?? 'No description available.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const Center(child: Text('No reviews yet.')),
                    const Center(child: Text('No instructions available.')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Read Sample', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Buy Now', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  const _InfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 32,
      width: 1.5,
      color: colorScheme.outline.withOpacity(0.15),
    );
  }
} 