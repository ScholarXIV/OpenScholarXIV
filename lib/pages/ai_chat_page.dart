// ignore_for_file: file_names

import 'package:arxiv/apis/gemini.dart';
import 'package:arxiv/components/api_settings.dart';
import 'package:arxiv/components/each_chat_message.dart';
import 'package:arxiv/components/prompt_suggestions.dart';
import 'package:arxiv/models/chat_message.dart';
import 'package:arxiv/models/paper.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:theme_provider/theme_provider.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key, required this.paperData});

  final Paper? paperData;

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  TextEditingController userMessageController = TextEditingController();
  ScrollController scrollController = ScrollController();
  var apiKey = "";
  List<ChatMessage> chatList = [];
  var apiKeySettingsOn = false;
  var toolsOn = true;

  final _systemLoadingTrigger = "SYMLOADINGANIMATION";

  Gemini? model;
  String selectedModelName = Gemini.defaultModelName;
  var geminiModels = [GeminiModelOption.fallback()];
  var isLoadingGeminiModels = false;

  String get selectedModelLabel {
    return geminiModels
        .firstWhere(
          (modelOption) => modelOption.id == selectedModelName,
          orElse: () => GeminiModelOption(
            id: selectedModelName,
            label: GeminiModelOption.labelFromModelName(selectedModelName),
          ),
        )
        .label;
  }

  bool get hasPaperTitle => widget.paperData?.title.trim().isNotEmpty ?? false;

  PopupMenuEntry<String> _buildLoadingModelsMenuItem() {
    return PopupMenuItem<String>(
      enabled: false,
      child: Row(
        children: [
          SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: ThemeProvider.themeOf(
                context,
              ).data.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 10.0),
          Text(
            "Loading models...",
            style: TextStyle(
              color: ThemeProvider.themeOf(
                context,
              ).data.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuEntry<String> _buildModelMenuItem(GeminiModelOption modelOption) {
    final isSelected = modelOption.id == selectedModelName;

    return PopupMenuItem<String>(
      value: modelOption.id,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check : Icons.auto_awesome_outlined,
            size: 18.0,
            color: ThemeProvider.themeOf(
              context,
            ).data.textTheme.bodyLarge?.color,
          ),
          const SizedBox(width: 10.0),
          Flexible(
            child: Text(
              modelOption.label,
              style: TextStyle(
                color: ThemeProvider.themeOf(
                  context,
                ).data.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> buildModelMenuItems() {
    if (isLoadingGeminiModels) return [_buildLoadingModelsMenuItem()];
    return geminiModels.map(_buildModelMenuItem).toList();
  }

  Widget _buildContextTag(String label, {double maxWidth = 120.0}) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: const EdgeInsets.only(right: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.0),
        color:
            ThemeProvider.themeOf(
              context,
            ).data.textTheme.bodyLarge?.color?.withAlpha(12) ??
            Colors.grey[100],
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12.0,
          color: ThemeProvider.themeOf(context).data.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildModelSelectorTag() {
    return PopupMenuButton<String>(
      tooltip: "Select model",
      enabled: !isLoadingGeminiModels && geminiModels.isNotEmpty,
      color: ThemeProvider.themeOf(context).data.scaffoldBackgroundColor,
      initialValue: hasGeminiModel(selectedModelName)
          ? selectedModelName
          : null,
      onSelected: selectGeminiModel,
      itemBuilder: (context) => buildModelMenuItems(),
      child: _buildContextTag(selectedModelLabel),
    );
  }

  var paperPromptSuggestions = [
    "Who wrote this paper?",
    "What is the title of this paper?",
    "What is the summary of this paper?",
    "What is the significance of this paper?",
    "Tell me a joke based on this paper's title?",
    "Can you explain like I am five years old?",
    "What do you know about the authors?",
    "Suggest and list related papers?",
    "How can this apply to my life?",
  ];

  var generalPromptSuggestions = [
    "What is arXiv?",
    "Tell me about OpenScholarXIV?",
    "Most profound research papers published?",
    "How can I get started writing research papers?",
    "Precautions to take while reading research papers?",
    "Where can I view the source code of OpenScholarXIV?",
    "List the main sections of research papers?",
    "Purpose of research papers?",
  ];

  void scrollToTheBottom() {
    setState(() {});
    try {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      //
    }
  }

  void chatWithAI() async {
    var message = userMessageController.text.trim();
    userMessageController.clear();

    final currentModel = model;

    if (message != "" && currentModel != null) {
      chatList.add(ChatMessage(Role.user, message));
      chatList.add(ChatMessage(Role.system, _systemLoadingTrigger));
      scrollToTheBottom();

      ChatMessage aiResponseObject = await currentModel.sendMessage(message);

      chatList.removeLast();
      setState(() {});
      chatList.add(aiResponseObject);
      setState(() {});

      scrollToTheBottom();
    }
  }

  void clearChat() async {
    chatList.clear();
    setState(() {});
  }

  bool hasGeminiModel(String modelName) {
    return geminiModels.any((modelOption) => modelOption.id == modelName);
  }

  String resolveSelectedModelName(dynamic savedModelName) {
    if (savedModelName is String && hasGeminiModel(savedModelName)) {
      return savedModelName;
    }

    if (hasGeminiModel(Gemini.defaultModelName)) {
      return Gemini.defaultModelName;
    }

    return geminiModels.first.id;
  }

  Future<void> selectGeminiModel(String modelName) async {
    if (modelName == selectedModelName || !hasGeminiModel(modelName)) {
      return;
    }

    selectedModelName = modelName;

    Box apiBox = await Hive.openBox("apibox");
    await apiBox.put("geminiModel", modelName);
    await Hive.close();

    if (apiKey.isNotEmpty) {
      model = await Gemini.newModel(
        apiKey,
        paper: widget.paperData,
        modelName: selectedModelName,
      );
      chatList.clear();
    }

    if (!mounted) return;
    setState(() {});
  }

  void configModel() async {
    Box apiBox = await Hive.openBox("apibox");
    apiKey = await apiBox.get("apikey") ?? "";
    final savedModelName = await apiBox.get("geminiModel");
    await Hive.close();

    if (apiKey.isNotEmpty) {
      if (mounted) {
        setState(() {
          apiKeySettingsOn = false;
          isLoadingGeminiModels = true;
        });
      }

      geminiModels = await Gemini.listModels(apiKey);
      selectedModelName = resolveSelectedModelName(savedModelName);
      model = await Gemini.newModel(
        apiKey,
        paper: widget.paperData,
        modelName: selectedModelName,
      );
      apiKeySettingsOn = false;
    } else {
      geminiModels = [GeminiModelOption.fallback()];
      selectedModelName = Gemini.defaultModelName;
      model = null;
      apiKeySettingsOn = true;
    }

    if (!mounted) return;
    setState(() {
      isLoadingGeminiModels = false;
    });
  }

  void toggleAPIKeySettings() {
    apiKeySettingsOn = !apiKeySettingsOn;
    setState(() {});
  }

  void toggleTools() async {
    toolsOn = !toolsOn;
    Box toolsBox = await Hive.openBox("toolsBox");
    await toolsBox.put("toolsBox", toolsOn);
    await Hive.close();
    setState(() {});
  }

  void getToggleTools() async {
    Box toolsBox = await Hive.openBox("toolsBox");
    toolsOn = await toolsBox.get("toolsBox") ?? true;
    await Hive.close();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getToggleTools();
    configModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "OpenScholarXIV",
          // style: TextStyle(fontSize: 15.0),
        ),
        actions: [
          // TOGGLE TOOLS
          IconButton(
            onPressed: () {
              toggleTools();
            },
            icon: const Icon(Icons.menu_open_rounded),
          ),
          // API KEY SETTINGS
          IconButton(
            onPressed: () {
              toggleAPIKeySettings();
            },
            icon: const Icon(Ionicons.key_outline),
          ),

          // CLEAR CHAT
          IconButton(
            onPressed: () {
              clearChat();
            },
            icon: const Icon(Icons.delete_forever_outlined),
          ),
          const SizedBox(width: 5.0),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10.0),

          Expanded(
            child: chatList.isEmpty || apiKeySettingsOn == true
                ? ListView(
                    padding: const EdgeInsets.only(top: 30.0),
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Icon(
                              Icons.auto_awesome_outlined,
                              size: 30.0,
                              color: ThemeProvider.themeOf(
                                context,
                              ).data.textTheme.bodyLarge?.color,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50.0,
                            ),
                            child: Text(
                              "This AI conversation is powered by $selectedModelLabel. You can have conversations about the current paper here.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          apiKeySettingsOn == true
                              ? APISettings(configAPIKey: configModel)
                              : PromptSuggestions(
                                  chatWithAI: chatWithAI,
                                  userMessageController: userMessageController,
                                  promptSuggestions: widget.paperData == null
                                      ? generalPromptSuggestions
                                      : paperPromptSuggestions,
                                ),
                        ],
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: chatList.length,
                    itemBuilder: (context, index) {
                      final item = chatList[index];
                      return EachChatMessage(response: item, toolsOn: toolsOn);
                    },
                  ),
          ),
          // Chat Box and Send Button
          Padding(
            padding: const EdgeInsets.only(left: 10.0, bottom: 8.0, top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      _buildModelSelectorTag(),
                      if (hasPaperTitle)
                        Expanded(
                          child: _buildContextTag(
                            widget.paperData!.title,
                            maxWidth: double.infinity,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 18.0, right: 18.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          color:
                              ThemeProvider.themeOf(context)
                                  .data
                                  .textTheme
                                  .bodyLarge
                                  ?.color
                                  ?.withAlpha(12) ??
                              Colors.grey[100],
                        ),
                        child: TextField(
                          controller: userMessageController,
                          enabled: !(apiKeySettingsOn == true),
                          cursorColor:
                              ThemeProvider.themeOf(context).id == "dark_theme"
                              ? Colors.white
                              : ThemeProvider.themeOf(
                                  context,
                                ).data.textTheme.bodyLarge?.color,
                          style: TextStyle(
                            color:
                                ThemeProvider.themeOf(context).id ==
                                    "dark_theme"
                                ? Colors.white
                                : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.paperData.toString() == ""
                                ? "ask about anything..."
                                : 'ask about the paper...',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        onPressed: apiKey.isEmpty || model == null
                            ? null
                            : chatWithAI,
                        icon: Icon(
                          Ionicons.paper_plane_outline,
                          color: ThemeProvider.themeOf(
                            context,
                          ).data.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
