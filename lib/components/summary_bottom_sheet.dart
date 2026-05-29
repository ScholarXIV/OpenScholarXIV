// ignore_for_file: file_names
import 'package:arxiv/models/paper.dart';
import 'package:arxiv/pages/full_screen_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';

class SummaryBottomSheet extends StatefulWidget {
  const SummaryBottomSheet({
    super.key,
    required this.paperData,
    required this.parseAndLaunchURL,
  });

  final Paper paperData;
  final Function parseAndLaunchURL;

  @override
  State<SummaryBottomSheet> createState() => _SummaryBottomSheetState();
}

class _SummaryBottomSheetState extends State<SummaryBottomSheet> {
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
    summary = widget.paperData.summary;
  }

  @override
  Widget build(BuildContext context) {
    String summary = widget.paperData.summary;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(top: 1.0),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                clipBehavior: Clip.hardEdge,
                margin: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Summary",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
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
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        resetSpeechRate();
                                      },
                                      child: Text(
                                        speedRate.toStringAsFixed(1).toString(),
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
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
                            padding: const EdgeInsets.only(bottom: 4.0),
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
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenSummaryPage(
                                    paperData: widget.paperData,
                                    parseAndLaunchURL: widget.parseAndLaunchURL,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Ionicons.expand_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.47,
                width: double.infinity,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: 10.0,
                        bottom: 100.0,
                      ),
                      child: (Paper.containsLatex(summary)
                          ? TeXView(
                              child: TeXViewDocument(
                                summary,
                                style: TeXViewStyle(
                                  contentColor: colorScheme.onSurface,
                                  textAlign: TeXViewTextAlign.left,
                                  fontStyle: TeXViewFontStyle(
                                    fontSize: 15,
                                    fontWeight: TeXViewFontWeight.normal,
                                  ),
                                ),
                              ),
                            )
                          : SelectableText(
                              summary,
                              style: const TextStyle(fontSize: 15.0),
                            )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
