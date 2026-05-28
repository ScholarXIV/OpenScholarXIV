// ignore_for_file: file_names

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:arxiv/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EachChatMessage extends StatefulWidget {
  const EachChatMessage({
    super.key,
    required this.response,
    required this.toolsOn,
  });

  final ChatMessage response;
  final dynamic toolsOn;

  @override
  State<EachChatMessage> createState() => _EachChatMessageState();
}

class _EachChatMessageState extends State<EachChatMessage> {
  var tts = FlutterTts();
  var speedRate = 0.5;
  var speedFactor = 0.1;
  var isSpeaking = false;

  final _markdownPrefix = "SYMMDX";

  bool isMarkdown(String content) {
    return content.substring(0, 6) == _markdownPrefix;
  }

  void readResponse() async {
    var message = isMarkdown(widget.response.content)
        ? widget.response.content.toString().substring(
            6,
            widget.response.content.length,
          )
        : widget.response.content;
    if (isSpeaking == false) {
      await tts.setLanguage("en-US");
      tts.setSpeechRate(speedRate);
      tts.speak(message);
    } else {
      tts.stop();
    }
    isSpeaking = !isSpeaking;
    setState(() {});
  }

  void shareResponse() async {
    var message = isMarkdown(widget.response.content)
        ? widget.response.content.toString().substring(
            6,
            widget.response.content.length,
          )
        : widget.response.content;
    Share.share(message.toString().trim());
  }

  void copyResponse() async {
    var message = isMarkdown(widget.response.content)
        ? widget.response.content.toString().substring(
            6,
            widget.response.content.length,
          )
        : widget.response.content;
    await Clipboard.setData(ClipboardData(text: message));
  }

  void getSpeedRate() async {
    final box = await Hive.openBox("speedRateBox");
    speedRate = await box.get("speedRate") ?? 0.5;
    await Hive.close();
    tts.setSpeechRate(speedRate);
  }

  @override
  void initState() {
    super.initState();
    getSpeedRate();
    tts.setCompletionHandler(() {
      isSpeaking = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: widget.response.role == Role.user
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.response.role == Role.ai ||
                        widget.response.role == Role.system
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6.0, left: 10.0),
                        child: Icon(
                          Icons.auto_awesome_outlined,
                          color: ThemeProvider.themeOf(
                            context,
                          ).data.textTheme.bodyLarge?.color,
                        ),
                      )
                    : Container(),
                Container(
                  constraints: BoxConstraints(
                    minWidth: 50.0,
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                    maxHeight: 500.0,
                  ),
                  margin: const EdgeInsets.only(
                    left: 8.0,
                    right: 8.0,
                    bottom: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeProvider.themeOf(context).id == "dark_theme"
                        ? ThemeProvider.themeOf(
                            context,
                          ).data.textTheme.bodyLarge?.color?.withAlpha(20)
                        : ThemeProvider.themeOf(context)
                                  .data
                                  .textTheme
                                  .bodyLarge
                                  ?.color
                                  ?.withAlpha(12) ??
                              Colors.grey[100],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: widget.response.role == Role.user
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13.0,
                            vertical: 10.0,
                          ),
                          child: Text(widget.response.content),
                        )
                      : widget.response.role == Role.system
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 3.0,
                          ),
                          child: LoadingAnimationWidget.prograssiveDots(
                            color:
                                ThemeProvider.themeOf(
                                  context,
                                ).data.textTheme.bodyLarge?.color ??
                                Colors.grey[700]!,
                            size: 30,
                          ),
                        )
                      : widget.response.content.toString().substring(0, 6) ==
                            "SYMMDX"
                      ? Markdown(
                          data: widget.response.content
                              .toString()
                              .substring(6, widget.response.content.length)
                              .trim(),
                          selectable: true,
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13.0,
                            vertical: 10.0,
                          ),
                          onTapLink: (text, href, title) =>
                              launchUrl(Uri.parse(href!)),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 10.0,
                          ),
                          child: AnimatedTextKit(
                            displayFullTextOnTap: true,
                            isRepeatingAnimation: false,
                            animatedTexts: [
                              TypewriterAnimatedText(
                                widget.response.content.toString().trim(),
                                textStyle: TextStyle(
                                  color:
                                      widget.response.content
                                              .toString()
                                              .trim()
                                              .startsWith(
                                                "GenerativeAIException",
                                              ) ||
                                          widget.response.content
                                              .toString()
                                              .trim()
                                              .startsWith("ClientException") ||
                                          widget.response.content
                                              .toString()
                                              .trim()
                                              .startsWith(
                                                "HandshakeException",
                                              ) ||
                                          widget.response.content
                                              .toString()
                                              .trim()
                                              .startsWith(
                                                "API key not valid",
                                              ) ||
                                          widget.response.content
                                              .toString()
                                              .trim()
                                              .startsWith(
                                                "An internal error has occurred",
                                              )
                                      ? Colors.redAccent
                                      : ThemeProvider.themeOf(
                                          context,
                                        ).data.textTheme.bodyLarge?.color,
                                ),
                                speed: const Duration(milliseconds: 20),
                              ),
                            ],
                          ),
                        ),
                ),
                widget.response.role == Role.user
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 10.0),
                        child: Icon(
                          Icons.person_outline,
                          color: ThemeProvider.themeOf(
                            context,
                          ).data.textTheme.bodyLarge?.color,
                        ),
                      )
                    : Container(),
              ],
            ),
            // TOOLS
            widget.response.role == Role.ai && widget.toolsOn == true
                ? Container(
                    padding: const EdgeInsets.only(left: 50.0, bottom: 14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            readResponse();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  ThemeProvider.themeOf(context)
                                      .data
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withAlpha(12) ??
                                  Colors.grey[100],
                              border: Border.all(color: Colors.grey[500]!),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Ionicons.volume_high_outline,
                                  size: 18.0,
                                  color: ThemeProvider.themeOf(
                                    context,
                                  ).data.textTheme.bodyLarge?.color,
                                ),
                                const SizedBox(width: 5.0),
                                const Text("Speak"),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        GestureDetector(
                          onTap: () {
                            copyResponse();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  ThemeProvider.themeOf(context)
                                      .data
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withAlpha(12) ??
                                  Colors.grey[100],
                              border: Border.all(color: Colors.grey[500]!),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Ionicons.copy_outline,
                                  size: 18.0,
                                  color: ThemeProvider.themeOf(
                                    context,
                                  ).data.textTheme.bodyLarge?.color,
                                ),
                                const SizedBox(width: 5.0),
                                const Text("Copy"),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        GestureDetector(
                          onTap: () => {shareResponse()},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  ThemeProvider.themeOf(context)
                                      .data
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withAlpha(12) ??
                                  Colors.grey[100],
                              border: Border.all(color: Colors.grey[500]!),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Ionicons.share_outline,
                                  size: 18.0,
                                  color: ThemeProvider.themeOf(
                                    context,
                                  ).data.textTheme.bodyLarge?.color,
                                ),
                                const SizedBox(width: 5.0),
                                const Text("Share"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ],
        ),
      ],
    );
  }
}
