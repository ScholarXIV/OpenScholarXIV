// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class APISettings extends StatefulWidget {
  const APISettings({super.key, required this.configAPIKey});

  final Function configAPIKey;

  @override
  State<APISettings> createState() => _APISettingsState();
}

class _APISettingsState extends State<APISettings> {
  TextEditingController apiKeyController = TextEditingController();
  var googleAIStudioURL = "https://aistudio.google.com/app/apikey";
  var apiKey = "";

  void getAPIKey() async {
    await launchUrl(Uri.parse(googleAIStudioURL));
  }

  void saveAPIKey() async {
    var newAPIKey = apiKeyController.text.trim();
    if (newAPIKey != "") {
      Box apiBox = await Hive.openBox("apibox");
      await apiBox.put("apikey", newAPIKey);
      await Hive.close();
    }
    widget.configAPIKey();
  }

  void clearAPIKey() async {
    apiKey = "";
    Box apiBox = await Hive.openBox("apibox");
    await apiBox.put("apikey", "");
    await Hive.close();
    widget.configAPIKey();
  }

  void getSavedAPIKey() async {
    Box apiBox = await Hive.openBox("apibox");
    apiKey = await apiBox.get("apikey") ?? "";
    await Hive.close();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getSavedAPIKey();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 10.0,
            ),
            child: const Text(
              "\nTo use this feature please get an API key from Google AI Studio and configure here.",
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 18.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: ThemeProvider.themeOf(context)
                      .data
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withAlpha(12) ??
                  Colors.grey[100],
            ),
            child: TextField(
              controller: apiKeyController,
              cursorColor: ThemeProvider.themeOf(context).id == "dark_theme"
                  ? Colors.white
                  : ThemeProvider.themeOf(context)
                      .data
                      .textTheme
                      .bodyLarge
                      ?.color,
              style: TextStyle(
                color: ThemeProvider.themeOf(context).id == "dark_theme"
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: apiKey == "" ? 'enter API key here..' : apiKey,
                hintStyle: TextStyle(color: Colors.grey[700]),
                border: InputBorder.none,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => {getAPIKey()},
                child: Container(
                  margin: const EdgeInsets.only(
                    top: 10.0,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 7.0),
                  decoration: BoxDecoration(
                    color: ThemeProvider.themeOf(context)
                            .data
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withAlpha(12) ??
                        Colors.grey[100],
                    border: Border.all(
                      color: Colors.grey[500]!,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Text("Get API Key"),
                ),
              ),
              const SizedBox(width: 10.0),
              GestureDetector(
                onTap: () {
                  saveAPIKey();
                },
                child: Container(
                  margin: const EdgeInsets.only(
                    top: 10.0,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 7.0),
                  decoration: BoxDecoration(
                    color: ThemeProvider.themeOf(context)
                            .data
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withAlpha(12) ??
                        Colors.grey[100],
                    border: Border.all(
                      color: Colors.grey[500]!,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Text("Save API Key"),
                ),
              ),
              const SizedBox(width: 10.0),
              GestureDetector(
                onTap: () {
                  clearAPIKey();
                },
                child: Container(
                  margin: const EdgeInsets.only(
                    top: 10.0,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 7.0),
                  decoration: BoxDecoration(
                    color: ThemeProvider.themeOf(context)
                            .data
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withAlpha(12) ??
                        Colors.grey[100],
                    border: Border.all(
                      color: Colors.grey[500]!,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Text("Clear API Key"),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(
              top: 80.0,
              left: 40.0,
              right: 40.0,
            ),
            child: Text(
              "Gemini API free-tier limits vary by model and project tier. Check your active quota in Google AI Studio. Unpaid Gemini API usage may be used by Google to improve its products and services.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500]!,
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
