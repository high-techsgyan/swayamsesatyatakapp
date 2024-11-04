import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfUrl;

  const PDFViewerScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late FlutterTts _flutterTts;
  String? _localPath;
  bool _isPlaying = false;
  bool _isLoading = true;
  String _pdfText = "";
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initializeTTS();
    _downloadAndSavePDF();
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_speechPitch);

    _flutterTts.setCompletionHandler(() {
      setState(() => _isPlaying = false);
    });
    _flutterTts.setErrorHandler((msg) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("TTS Error: $msg")));
    });
  }

  Future<void> _downloadAndSavePDF() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final documentDirectory = await getApplicationDocumentsDirectory();
        final filePath = "${documentDirectory.path}/temp.pdf";
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localPath = filePath;
          _isLoading = false;
        });
        await _extractTextFromPDF(filePath);
      } else {
        throw Exception("Failed to load PDF from URL");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error downloading PDF: $e")));
    }
  }

  Future<void> _extractTextFromPDF(String path) async {
    // Note: If you still need to extract text from the PDF,
    // you'll need a package that supports text extraction.
    // Since you requested to remove editing features, you can skip this if not needed.
  }

  Future<void> _startTextToSpeech() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
    } else {
      if (_pdfText.isNotEmpty) {
        await _flutterTts.speak(_pdfText);
        setState(() => _isPlaying = true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("No text found in PDF")));
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PDF Viewer"),
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
            onPressed: _pdfText.isEmpty ? null : _startTextToSpeech,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _localPath == null
              ? Center(child: Text("Failed to load PDF"))
              : PDFView(
                  filePath: _localPath,
                  onRender: (_pages) {
                    setState(() {
                      _totalPages = _pages ?? 0;
                    });
                  },
                  onPageChanged: (page, total) {
                    setState(() {
                      _currentPage = page!;
                    });
                  },
                ),
    );
  }
}
