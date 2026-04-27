import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameWebView extends StatefulWidget {
  const GameWebView({super.key});

  @override
  State<GameWebView> createState() => _GameWebViewState();
}

class _GameWebViewState extends State<GameWebView> {
  final String _viewId =
      'game-iframe-${DateTime.now().millisecondsSinceEpoch}';
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    try {
      String htmlContent = await rootBundle.loadString('assets/game.html');
      final phaserBytes = await rootBundle.load('assets/phaser.min.js');
      final phaserBase64 = base64Encode(phaserBytes.buffer.asUint8List());

      htmlContent = htmlContent.replaceAll(
        '<script src="phaser.min.js"></script>',
        '<script src="data:text/javascript;base64,$phaserBase64"></script>',
      );

      final blob = html.Blob([htmlContent], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0';

      // Register factory first
      ui.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => iframe,
      );

      // Only show HtmlElementView AFTER registration
      if (mounted) {
        setState(() => _registered = true);
      }
    } catch (e) {
      debugPrint('ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_registered) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a1a2e),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 252, 183, 199),
              ),
              SizedBox(height: 20),
              Text(
                'Loading game...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SizedBox.expand(
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }
}