// ignore_for_file: file_names

import 'package:flutter/material.dart';

class PromptSuggestions extends StatefulWidget {
  const PromptSuggestions({
    super.key,
    required this.chatWithAI,
    required this.userMessageController,
    required this.promptSuggestions,
  });

  final Function chatWithAI;
  final TextEditingController userMessageController;
  final List promptSuggestions;

  @override
  State<PromptSuggestions> createState() => _PromptSuggestionsState();
}

class _PromptSuggestionsState extends State<PromptSuggestions> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: widget.promptSuggestions
            .map(
              (suggestion) => GestureDetector(
                onTap: () {
                  widget.userMessageController.text = suggestion;
                  widget.chatWithAI();
                },
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(
                      top: 10.0,
                      left: 20.0,
                      right: 20.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(suggestion, textAlign: TextAlign.center),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
