// ignore_for_file: file_names

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:arxiv/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:arxiv/services/speech_rate_store.dart';
import 'package:ionicons_plus/ionicons_plus.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:share_plus/share_plus.dart';
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
  final SpeechRateStore _speechRateStore = SpeechRateStore();
  var speedRate = SpeechRateStore.defaultRate;
  var speedFactor = 0.1;
  var isSpeaking = false;
  var toolsRevealed = false;

  final _markdownPrefix = "SYMMDX";

  bool get showTools {
    return widget.response.role == Role.ai &&
        (widget.toolsOn == true || toolsRevealed);
  }

  bool isMarkdown(String content) {
    return content.startsWith(_markdownPrefix);
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

  void revealTools() {
    if (widget.response.role != Role.ai || toolsRevealed) return;

    setState(() {
      toolsRevealed = true;
    });
  }

  Future<void> getSpeedRate() async {
    final rate = await _speechRateStore.load();
    if (!mounted) return;
    setState(() => speedRate = rate);
    await tts.setSpeechRate(speedRate);
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
    final colorScheme = Theme.of(context).colorScheme;

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
                          color: colorScheme.primary,
                        ),
                      )
                    : Container(),
                GestureDetector(
                  onLongPress: revealTools,
                  child: Container(
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
                      color: widget.response.role == Role.user
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: widget.response.role == Role.user
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13.0,
                              vertical: 10.0,
                            ),
                            child: Text(
                              widget.response.content,
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          )
                        : widget.response.role == Role.system
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 3.0,
                            ),
                            child: LoadingAnimationWidget.prograssiveDots(
                              color: colorScheme.primary,
                              size: 30,
                            ),
                          )
                        : isMarkdown(widget.response.content)
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
                                                .startsWith(
                                                  "ClientException",
                                                ) ||
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
                                        ? colorScheme.error
                                        : colorScheme.onSurface,
                                  ),
                                  speed: const Duration(milliseconds: 20),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                widget.response.role == Role.user
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 10.0),
                        child: Icon(
                          Icons.person_outline,
                          color: colorScheme.primary,
                        ),
                      )
                    : Container(),
              ],
            ),
            // TOOLS
            showTools
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
                              color: colorScheme.surfaceContainerHighest,
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Ionicons.volume_high_outline,
                                  size: 18.0,
                                  color: colorScheme.primary,
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
                              color: colorScheme.surfaceContainerHighest,
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Ionicons.copy_outline,
                                  size: 18.0,
                                  color: colorScheme.primary,
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
                              color: colorScheme.surfaceContainerHighest,
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Ionicons.share_outline,
                                  size: 18.0,
                                  color: colorScheme.primary,
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
