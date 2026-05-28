// ignore_for_file: file_names
import 'package:arxiv/models/paper.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tex/flutter_tex.dart';

import 'package:hive/hive.dart';
import 'package:theme_provider/theme_provider.dart';

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
  var tts = FlutterTts();
  var isSpeaking = false;
  var summary = "";
  var speedRate = 0.5;
  var speedFactor = 0.1;

  void readSummary() async {
    if (isSpeaking == false) {
      await tts.setLanguage("en-US");
      tts.speak(summary);
    } else {
      tts.stop();
    }
    isSpeaking = !isSpeaking;
    setState(() {});
  }

  void changeSpeedRate({bool? increase}) async {
    if (increase == true) {
      if (speedRate < 0.9) {
        speedRate += speedFactor;
      }
    } else {
      if (speedRate >= 0.1) {
        speedRate -= speedFactor;
      }
    }
    tts.stop();
    tts.setSpeechRate(speedRate);
    isSpeaking = false;
    readSummary();
    final box = await Hive.openBox("speedRateBox");
    box.put("speedRate", speedRate);
    await Hive.close();
  }

  void getSpeedRate() async {
    final box = await Hive.openBox("speedRateBox");
    speedRate = await box.get("speedRate");
    await Hive.close();
    tts.setSpeechRate(speedRate);
  }

  void resetSpeechRate() async {
    speedRate = 0.5;
    final box = await Hive.openBox("speedRateBox");
    box.put("speedRate", speedRate);
    await Hive.close();
    tts.stop();
    tts.setSpeechRate(speedRate);
    isSpeaking = false;
    readSummary();
  }

  @override
  void initState() {
    super.initState();
    getSpeedRate();
    tts.setCompletionHandler(() {
      isSpeaking = false;
      setState(() {});
    });
    summary = widget.paperData.summary
        .trim()
        .replaceAll(RegExp(r'\\n'), ' ')
        .replaceAll(RegExp(r'\\'), '');
  }

  @override
  Widget build(BuildContext context) {
    String summary = widget.paperData.summary;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary"),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isSpeaking == true
                  ? Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (speedRate > 0.0) {
                              changeSpeedRate(increase: false);
                            }
                          },
                          icon: Icon(
                            Icons.remove,
                            color:
                                ThemeProvider.themeOf(context).id ==
                                    "mixed_theme"
                                ? Colors.grey[200]
                                : ThemeProvider.themeOf(
                                    context,
                                  ).data.textTheme.bodyLarge?.color,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            resetSpeechRate();
                          },
                          child: Text(
                            speedRate.toStringAsFixed(1).toString(),
                            style: TextStyle(
                              color:
                                  ThemeProvider.themeOf(context).id ==
                                      "mixed_theme"
                                  ? Colors.grey[200]
                                  : ThemeProvider.themeOf(
                                      context,
                                    ).data.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (speedRate < 1.0) {
                              changeSpeedRate(increase: true);
                            }
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    )
                  : Container(),
              IconButton(
                onPressed: () {
                  readSummary();
                },
                icon: Icon(
                  isSpeaking == true
                      ? Ionicons.stop_outline
                      : Ionicons.volume_high_outline,
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
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0),
            child: Paper.containsLatex(summary)
                ? TeXView(
                    child: TeXViewDocument(
                      summary,
                      style: TeXViewStyle(
                        contentColor: ThemeProvider.themeOf(
                          context,
                        ).data.textTheme.bodyLarge?.color,
                        textAlign: TeXViewTextAlign.left,
                        fontStyle: TeXViewFontStyle(
                          fontSize: 17,
                          fontWeight: TeXViewFontWeight.normal,
                        ),
                      ),
                    ),
                  )
                : SelectableText(
                    summary,
                    style: const TextStyle(fontSize: 17.0),
                  ),
          ),
        ],
      ),
    );
  }
}
