// ignore_for_file: file_names

import 'package:arxiv/apis/gemini.dart';
import 'package:arxiv/components/api_settings.dart';
import 'package:arxiv/components/each_chat_message.dart';
import 'package:arxiv/components/prompt_suggestions.dart';
import 'package:arxiv/models/chat_message.dart';
import 'package:arxiv/models/chat_thread.dart';
import 'package:arxiv/models/paper.dart';
import 'package:arxiv/services/chat_history_store.dart';
import 'package:arxiv/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';

enum _ChatThreadMenuAction { rename, delete }

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key, required this.paperData});

  final Paper? paperData;

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final ChatHistoryStore _chatHistoryStore = ChatHistoryStore();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController userMessageController = TextEditingController();
  ScrollController scrollController = ScrollController();
  var apiKey = "";
  List<ChatMessage> chatList = [];
  List<ChatThread> chatThreads = [];
  ChatThread? activeThread;
  Paper? activePaperData;
  String? renamingThreadId;
  String renameDraft = "";
  var apiKeySettingsOn = false;
  var toolsOn = true;
  var isLoadingChatHistory = true;

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

  bool get hasPaperTitle => activePaperData?.title.trim().isNotEmpty ?? false;

  PopupMenuEntry<String> _buildLoadingModelsMenuItem() {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuItem<String>(
      enabled: false,
      child: Row(
        children: [
          SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10.0),
          Text(
            "Loading models...",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  PopupMenuEntry<String> _buildModelMenuItem(GeminiModelOption modelOption) {
    final isSelected = modelOption.id == selectedModelName;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuItem<String>(
      value: modelOption.id,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check : Icons.auto_awesome_outlined,
            size: 18.0,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
          const SizedBox(width: 10.0),
          Flexible(
            child: Text(
              modelOption.label,
              style: TextStyle(color: colorScheme.onSurface),
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

  Widget _buildContextTag(
    String label, {
    double maxWidth = 120.0,
    bool selected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: const EdgeInsets.only(right: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.0),
        color: selected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12.0,
          color: selected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildModelSelectorTag() {
    return PopupMenuButton<String>(
      tooltip: "Select model",
      enabled: !isLoadingGeminiModels && geminiModels.isNotEmpty,
      color: Theme.of(context).colorScheme.surface,
      initialValue: hasGeminiModel(selectedModelName)
          ? selectedModelName
          : null,
      onSelected: selectGeminiModel,
      itemBuilder: (context) => buildModelMenuItems(),
      child: _buildContextTag(selectedModelLabel, selected: true),
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
    // "Where can I view the source code of OpenScholarXIV?",
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

  List<ChatMessage> messagesToPersist() {
    return chatList
        .where((message) => message.role != Role.system)
        .map((message) => ChatMessage(message.role, message.content))
        .toList();
  }

  Future<void> loadChatHistory() async {
    final threads = await _chatHistoryStore.loadThreads();
    if (!mounted) return;

    setState(() {
      chatThreads = threads;
      isLoadingChatHistory = false;
    });
  }

  Future<void> persistActiveThread() async {
    final thread = activeThread;
    if (thread == null) return;

    thread.messages = messagesToPersist();
    thread.modelName = selectedModelName;
    thread.paperData = activePaperData;
    await _chatHistoryStore.saveThread(thread);
    await loadChatHistory();
  }

  Future<void> ensureActiveThread(String firstMessage) async {
    if (activeThread != null) return;

    activeThread = await _chatHistoryStore.createThread(
      modelName: selectedModelName,
      paperData: activePaperData,
      title: firstMessage,
      messages: messagesToPersist(),
    );
    await loadChatHistory();
  }

  Future<void> rebuildModel({List<ChatMessage> history = const []}) async {
    if (apiKey.isEmpty) {
      model = null;
      return;
    }

    model = await Gemini.newModel(
      apiKey,
      paper: activePaperData,
      modelName: selectedModelName,
      history: history,
    );
  }

  Future<void> startNewChat() async {
    activeThread = null;
    activePaperData = widget.paperData;
    chatList.clear();
    apiKeySettingsOn = apiKey.isEmpty;
    await rebuildModel();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> chatWithAI() async {
    var message = userMessageController.text.trim();
    userMessageController.clear();

    final currentModel = model;

    if (message != "" && currentModel != null) {
      chatList.add(ChatMessage(Role.user, message));
      chatList.add(ChatMessage(Role.system, _systemLoadingTrigger));
      scrollToTheBottom();
      await ensureActiveThread(message);
      await persistActiveThread();

      ChatMessage aiResponseObject = await currentModel.sendMessage(message);

      if (chatList.isNotEmpty &&
          chatList.last.role == Role.system &&
          chatList.last.content == _systemLoadingTrigger) {
        chatList.removeLast();
      }
      setState(() {});
      chatList.add(aiResponseObject);
      setState(() {});
      await persistActiveThread();

      scrollToTheBottom();
    }
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
        paper: activePaperData,
        modelName: selectedModelName,
        history: messagesToPersist(),
      );
      await persistActiveThread();
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
      selectedModelName = resolveSelectedModelName(
        activeThread?.modelName ?? savedModelName,
      );
      model = await Gemini.newModel(
        apiKey,
        paper: activePaperData,
        modelName: selectedModelName,
        history: messagesToPersist(),
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

  void getToggleTools() async {
    Box toolsBox = await Hive.openBox("toolsBox");
    toolsOn = await toolsBox.get("toolsBox") ?? true;
    await Hive.close();
    setState(() {});
  }

  String chatThreadSubtitle(ChatThread thread) {
    return firstUserMessagePreview(thread);
  }

  String firstUserMessagePreview(ChatThread thread) {
    for (final message in thread.messages) {
      if (message.role != Role.user) continue;

      var content = message.content.trim().replaceAll(RegExp(r"\s+"), " ");
      if (content.startsWith("SYMMDX")) {
        content = content.substring(6).trim();
      }
      if (content.isNotEmpty) {
        return content.length > 70
            ? "${content.substring(0, 67).trimRight()}..."
            : content;
      }
    }
    return "";
  }

  String formatThreadDate(DateTime date) {
    final now = DateTime.now();
    final sameDay =
        now.year == date.year && now.month == date.month && now.day == date.day;
    if (sameDay) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }

    if (now.year == date.year) {
      return "${date.month}/${date.day}";
    }

    return "${date.year}/${date.month}/${date.day}";
  }

  Future<void> selectChatThread(ChatThread thread) async {
    activeThread = thread;
    activePaperData = thread.paperData;
    chatList = thread.messages
        .map((message) => ChatMessage(message.role, message.content))
        .toList();
    selectedModelName = resolveSelectedModelName(thread.modelName);
    apiKeySettingsOn = apiKey.isEmpty;
    await rebuildModel(history: messagesToPersist());

    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToTheBottom());
  }

  void startRenamingChatThread(ChatThread thread) {
    setState(() {
      renamingThreadId = thread.id;
      renameDraft = thread.title;
    });
  }

  void cancelRenamingChatThread() {
    setState(() {
      renamingThreadId = null;
      renameDraft = "";
    });
  }

  Future<void> saveRenamedChatThread(ChatThread thread) async {
    final title = renameDraft;
    setState(() {
      renamingThreadId = null;
      renameDraft = "";
    });

    await _chatHistoryStore.renameThread(thread, title);
    if (activeThread?.id == thread.id) {
      activeThread?.title = thread.title;
    }
    await loadChatHistory();
  }

  Future<void> confirmDeleteChatThread(ChatThread thread) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete chat?"),
        content: Text(
          "This will permanently delete \"${thread.title}\" from this device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await _chatHistoryStore.deleteThread(thread.id);
    if (activeThread?.id == thread.id) {
      await startNewChat();
    }
    await loadChatHistory();
  }

  void runAfterClosingDrawer(Future<void> Function() action) {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await action();
    });
  }

  Widget buildChatHistoryDrawer() {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 10.0, 8.0, 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Chats",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "New chat",
                    onPressed: () {
                      Navigator.pop(context);
                      startNewChat();
                    },
                    icon: const Icon(Icons.add_comment_outlined),
                  ),
                ],
              ),
            ),
            Divider(color: colorScheme.outlineVariant, height: 1.0),
            Expanded(
              child: isLoadingChatHistory
                  ? const Center(child: CircularProgressIndicator())
                  : chatThreads.isEmpty
                  ? Center(
                      child: Text(
                        "No saved chats yet",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: chatThreads.length,
                      itemBuilder: (context, index) {
                        final thread = chatThreads[index];
                        final isSelected = activeThread?.id == thread.id;
                        final isRenaming = renamingThreadId == thread.id;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: colorScheme.primaryContainer,
                          leading: Icon(
                            thread.paperData == null
                                ? Icons.auto_awesome_outlined
                                : Icons.description_outlined,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          title: isRenaming
                              ? TextFormField(
                                  key: ValueKey("rename_${thread.id}"),
                                  initialValue: renameDraft,
                                  autofocus: true,
                                  maxLines: 1,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    renameDraft = value;
                                  },
                                  onFieldSubmitted: (_) {
                                    saveRenamedChatThread(thread);
                                  },
                                )
                              : Text(
                                  thread.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          subtitle: Text(
                            chatThreadSubtitle(thread),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isRenaming
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: "Save",
                                      onPressed: () {
                                        saveRenamedChatThread(thread);
                                      },
                                      icon: const Icon(Icons.check),
                                    ),
                                    IconButton(
                                      tooltip: "Cancel",
                                      onPressed: cancelRenamingChatThread,
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      formatThreadDate(thread.updatedAt),
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    PopupMenuButton<_ChatThreadMenuAction>(
                                      tooltip: "Chat options",
                                      onSelected: (action) {
                                        if (action ==
                                            _ChatThreadMenuAction.rename) {
                                          startRenamingChatThread(thread);
                                        } else {
                                          runAfterClosingDrawer(
                                            () =>
                                                confirmDeleteChatThread(thread),
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: _ChatThreadMenuAction.rename,
                                          child: Text("Rename"),
                                        ),
                                        PopupMenuItem(
                                          value: _ChatThreadMenuAction.delete,
                                          child: Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                          onTap: () {
                            if (isRenaming) return;
                            Navigator.pop(context);
                            selectChatThread(thread);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    activePaperData = widget.paperData;
    loadChatHistory();
    getToggleTools();
    configModel();
  }

  @override
  void dispose() {
    userMessageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: buildChatHistoryDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
        title: const Text(
          "OpenScholarXIV",
          // style: TextStyle(fontSize: 15.0),
        ),
        actions: [
          // API KEY SETTINGS
          IconButton(
            onPressed: () {
              toggleAPIKeySettings();
            },
            icon: const Icon(Ionicons.key_outline),
          ),

          // NEW CHAT
          IconButton(
            onPressed: () {
              startNewChat();
            },
            icon: const Icon(Icons.add_comment_outlined),
          ),
          // CHAT HISTORY
          IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: const Icon(Icons.history_outlined),
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
                              color: colorScheme.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50.0,
                            ),
                            child: Text(
                              activePaperData == null
                                  ? "This AI conversation is powered by $selectedModelLabel."
                                  : "This AI conversation is powered by $selectedModelLabel. You can have conversations about the current paper here.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          apiKeySettingsOn == true
                              ? APISettings(configAPIKey: configModel)
                              : PromptSuggestions(
                                  chatWithAI: chatWithAI,
                                  userMessageController: userMessageController,
                                  promptSuggestions: activePaperData == null
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
                            activePaperData!.title,
                            maxWidth: double.infinity,
                            selected: true,
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
                          color: subtleSurfaceColor(colorScheme),
                        ),
                        child: TextField(
                          controller: userMessageController,
                          enabled: !(apiKeySettingsOn == true),
                          cursorColor: colorScheme.primary,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: activePaperData == null
                                ? "ask about anything..."
                                : 'ask about the paper...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
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
                          color: apiKey.isEmpty || model == null
                              ? colorScheme.onSurface.withAlpha(64)
                              : colorScheme.primary,
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
