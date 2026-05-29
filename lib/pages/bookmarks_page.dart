// ignore_for_file: file_names
import 'package:arxiv/components/each_paper_card.dart';
import 'package:arxiv/components/loading_indicator.dart';
import 'package:arxiv/models/paper.dart';
import 'package:arxiv/pages/paper_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({
    super.key,
    required this.downloadPaper,
    required this.parseAndLaunchURL,
    required this.onSearchQuerySelected,
  });

  final Function downloadPaper;
  final Function parseAndLaunchURL;
  final Future<void> Function(String query) onSearchQuerySelected;

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  var bookmarks = [];
  bool isLoading = true;
  int notesRefreshToken = 0;

  Future<void> getBookmarks() async {
    Box bookmarksBox = await Hive.openBox("bookmarks");
    bookmarks = await bookmarksBox.get("bookmarks") ?? [];
    await Hive.close();
    isLoading = false;
    setState(() {});
  }

  void clearBookmarks() async {
    isLoading = true;
    setState(() {});
    Box bookmarksBox = await Hive.openBox("bookmarks");
    await bookmarksBox.clear();
    await Hive.close();
    bookmarks = [];
    isLoading = false;
    setState(() {});
  }

  Future<void> openPaperDetails(Paper paper) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaperDetailPage(
          paper: paper,
          downloadPaper: widget.downloadPaper,
          parseAndLaunchURL: widget.parseAndLaunchURL,
          onSearchQuerySelected: widget.onSearchQuerySelected,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      notesRefreshToken++;
    });
  }

  @override
  void initState() {
    super.initState();
    getBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookmarks"),
        actions: [
          IconButton(
            onPressed: () {
              clearBookmarks();
            },
            icon: const Icon(Icons.delete_forever_outlined),
          ),
        ],
      ),
      body: isLoading == true
          ? const LoadingIndicator(topPadding: 50.0)
          : bookmarks.isNotEmpty
          ? LiquidPullToRefresh(
              onRefresh: getBookmarks,
              backgroundColor: colorScheme.surface,
              color: colorScheme.primary,
              animSpeedFactor: 2.0,
              child: ListView(
                children: bookmarks
                    .map(
                      (eachPaper) => EachPaperCard(
                        eachPaper: eachPaper,
                        downloadPaper: widget.downloadPaper,
                        parseAndLaunchURL: widget.parseAndLaunchURL,
                        isBookmarked: true,
                        onCardTap: () => openPaperDetails(eachPaper),
                        notesRefreshToken: notesRefreshToken,
                      ),
                    )
                    .toList(),
              ),
            )
          : Center(
              child: Text(
                "No Bookmarks Yet!",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16.0,
                ),
              ),
            ),
    );
  }
}
