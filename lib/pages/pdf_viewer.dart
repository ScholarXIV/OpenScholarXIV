// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewer extends StatefulWidget {
  const PDFViewer({
    super.key,
    required this.paperTitle,
    required this.savePath,
    required this.pdfURL,
    required this.urlType,
    required this.downloadPaper,
  });

  final String paperTitle;
  final String savePath;
  final String pdfURL;
  final int urlType;
  final Function downloadPaper;

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.paperTitle, style: const TextStyle(fontSize: 16.0)),
        actions: [
          IconButton(
            onPressed: () => {widget.downloadPaper(widget.pdfURL)},
            icon: const Icon(Icons.downloading_outlined),
          ),
        ],
      ),
      body: widget.urlType == 1
          ? SfPdfViewer.network(widget.pdfURL, enableTextSelection: true)
          : PDFView(
              filePath: widget.savePath,
              autoSpacing: false,
              pageFling: false,
            ),
    );
  }
}
