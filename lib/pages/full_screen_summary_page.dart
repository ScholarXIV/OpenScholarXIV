// ignore_for_file: file_names
import 'package:arxiv/models/paper.dart';
import 'package:arxiv/services/speech_rate_store.dart';
import 'package:flutter/material.dart';
import 'package:ionicons_plus/ionicons_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tex/flutter_tex.dart';

class FullScreenSummaryPage extends StatefulWidget {
  const FullScreenSummaryPage({
    super.key,
    required this.paperData,
    required this.parseAndLaunchURL,
  });

  final Paper paperData;
  final Function parseAndLaunchURL;

  @override
  State<FullScreenSummaryPage> createState() => _FullScreenSummaryPageState();
}

class _FullScreenSummaryPageState extends State<FullScreenSummaryPage> {
  final FlutterTts _tts = FlutterTts();
  final SpeechRateStore _speechRateStore = SpeechRateStore();
  var isSpeaking = false;
  var summary = "";
  var speedRate = SpeechRateStore.defaultRate;
  var speedFactor = 0.1;

  Future<void> _loadSpeedRate() async {
    final rate = await _speechRateStore.load();
    if (!mounted) return;
    setState(() => speedRate = rate);
    await _tts.setSpeechRate(speedRate);
  }

  Future<void> readSummary() async {
    if (!isSpeaking) {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(speedRate);
      await _tts.speak(summary);
    } else {
      await _tts.stop();
    }
    if (!mounted) return;
    setState(() => isSpeaking = !isSpeaking);
  }

  Future<void> changeSpeedRate({bool? increase}) async {
    if (increase == true) {
      if (speedRate < 0.9) {
        speedRate += speedFactor;
      }
    } else if (speedRate >= 0.1) {
      speedRate -= speedFactor;
    }
    await _tts.stop();
    await _tts.setSpeechRate(speedRate);
    isSpeaking = false;
    await _speechRateStore.save(speedRate);
    if (!mounted) return;
    setState(() {});
    await readSummary();
  }

  Future<void> resetSpeechRate() async {
    speedRate = SpeechRateStore.defaultRate;
    await _speechRateStore.save(speedRate);
    await _tts.stop();
    await _tts.setSpeechRate(speedRate);
    isSpeaking = false;
    if (!mounted) return;
    setState(() {});
    await readSummary();
  }

  @override
  void initState() {
    super.initState();
    _loadSpeedRate();
    _tts.setCompletionHandler(() {
      isSpeaking = false;
      if (mounted) setState(() {});
    });
    summary = widget.paperData.summary
        .trim()
        .replaceAll(RegExp(r'\\n'), ' ')
        .replaceAll(RegExp(r'\\'), '');
  }

  @override
  Widget build(BuildContext context) {
    final summaryText = widget.paperData.summary;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary"),
        actions: [
          if (isSpeaking)
            IconButton(
              onPressed: () {
                if (speedRate > 0.0) {
                  changeSpeedRate(increase: false);
                }
              },
              icon: Icon(Icons.remove, color: colorScheme.onSurfaceVariant),
            ),
          if (isSpeaking)
            TextButton(
              onPressed: resetSpeechRate,
              child: Text(
                speedRate.toStringAsFixed(1),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          if (isSpeaking)
            IconButton(
              onPressed: () {
                if (speedRate < 1.0) {
                  changeSpeedRate(increase: true);
                }
              },
              icon: Icon(Icons.add, color: colorScheme.onSurfaceVariant),
            ),
          IconButton(
            onPressed: readSummary,
            icon: Icon(
              isSpeaking ? Ionicons.stop_outline : Ionicons.volume_high_outline,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5.0, bottom: 3.0),
            child: IconButton(
              onPressed: () {
                widget.parseAndLaunchURL(
                  widget.paperData.pdfUrl.isNotEmpty
                      ? widget.paperData.pdfUrl
                      : widget.paperData.id,
                  widget.paperData.title,
                );
              },
              icon: const Icon(Ionicons.open_outline),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0),
            child: Paper.containsLatex(summaryText)
                ? TeXView(
                    child: TeXViewDocument(
                      summaryText,
                      style: TeXViewStyle(
                        contentColor: colorScheme.onSurface,
                        textAlign: TeXViewTextAlign.left,
                        fontStyle: TeXViewFontStyle(
                          fontSize: 17,
                          fontWeight: TeXViewFontWeight.normal,
                        ),
                      ),
                    ),
                  )
                : SelectableText(
                    summaryText,
                    style: const TextStyle(fontSize: 17.0),
                  ),
          ),
        ],
      ),
    );
  }
}
