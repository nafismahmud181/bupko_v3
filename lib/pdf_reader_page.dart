import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfReaderPage extends StatelessWidget {
  final String pdfUrl;
  final String bookTitle;

  const PdfReaderPage({Key? key, required this.pdfUrl, required this.bookTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bookTitle),
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
} 