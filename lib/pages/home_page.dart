// ignore_for_file: file_names
import 'package:arxiv/apis/arxiv.dart';
import 'package:arxiv/components/each_paper_card.dart';
import 'package:arxiv/components/paper_card_skeleton.dart';
import 'package:arxiv/components/search_box.dart';
import 'package:arxiv/data/arxiv_categories.dart';
import 'package:arxiv/models/paper.dart';
import 'package:arxiv/pages/ai_chat_page.dart';
import 'package:arxiv/pages/bookmarks_page.dart';
import 'package:arxiv/pages/paper_detail_page.dart';
import 'package:arxiv/pages/paper_notes_page.dart';
import 'package:arxiv/pages/pdf_viewer.dart';
import 'package:arxiv/pages/settings_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ionicons_plus/ionicons_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var sourceCodeURL = "https://github.com/ScholarXIV/OpenScholarXIV";
  var scholarXivURL = "https://ScholarXIV.com";
  int startPagination = 0;
  int maxContent = 30;
  int paginationGap = 30;
  var pdfBaseURL = "https://arxiv.org/pdf";
  bool sortOrderNewest = true;

  var isHomeScreenLoading = true;
  TextEditingController searchTermController = TextEditingController();
  int notesRefreshToken = 0;

  var dio = Dio();
  List<Paper> data = [];
  ArxivSearchResult? lastSearchResult;
  String? homeScreenError;
  int _searchRequestSerial = 0;

  Future<void> search({bool? resetPagination}) async {
    final requestSerial = ++_searchRequestSerial;
    if (resetPagination == true) {
      startPagination = 0;
    }
    setState(() {
      isHomeScreenLoading = true;
      homeScreenError = null;
      data = [];
    });

    var searchTerm = searchTermController.text.toString().trim();
    late final ArxivSearchResult result;
    if (searchTerm.isNotEmpty) {
      result = await Arxiv.searchWithMetadata(
        searchTerm,
        page: startPagination,
        pageSize: maxContent,
      );
    } else {
      result = await suggestedPapers();
    }

    if (!mounted || requestSerial != _searchRequestSerial) {
      return;
    }

    setState(() {
      lastSearchResult = result;
      data = result.papers;
      homeScreenError = result.errorMessage;
      isHomeScreenLoading = false;
    });
  }

  Future<void> runFeedSearch(String query) async {
    searchTermController.text = query;
    await search(resetPagination: true);
  }

  Future<void> searchCategory(ArxivCategory category) async {
    await runFeedSearch(category.query);
  }

  Future<void> toggleSortOrder() async {
    setState(() {
      sortOrderNewest = !sortOrderNewest; // Toggle the sorting order
    });
    await sortPapersByDate(); // Apply the sorting after toggling
  }

  Future<void> sortPapersByDate() async {
    if (data.isNotEmpty) {
      // Sort papers based on publishedAt date
      data.sort((a, b) {
        // Parsing the publishedAt date strings into DateTime objects
        DateTime dateA = DateTime.parse(a.publishedAt);
        DateTime dateB = DateTime.parse(b.publishedAt);

        return sortOrderNewest
            ? dateB.compareTo(dateA)
            : dateA.compareTo(dateB);
      });
      setState(() {});
    }
  }

  Future<ArxivSearchResult> suggestedPapers() async {
    return Arxiv.suggestWithMetadata(pageSize: maxContent);
  }

  var paperTitle = "";
  var savePath = "";
  var pdfURL = "";
  dynamic downloadPath = "";

  Future<void> parseAndLaunchURL(String currentURL, String title) async {
    paperTitle = title;

    pdfURL = pdfUrlFor(currentURL);
    var splitURL = pdfURL.split("/");
    var id = splitURL[splitURL.length - 1];
    var urlType = 0;
    if (id.contains(".") == true) {
      urlType = 1;
    } else {
      urlType = 2;
    }

    final Uri parsedURL = Uri.parse(pdfURL);
    savePath = '${(await getTemporaryDirectory()).path}/paper3.pdf';

    if (urlType == 2) {
      var result = await dio.downloadUri(parsedURL, savePath);
      if (result.statusCode != 200) {}
    }

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewer(
          paperTitle: paperTitle,
          savePath: savePath,
          pdfURL: pdfURL,
          urlType: urlType,
          downloadPaper: downloadPaper,
        ),
      ),
    );
    setState(() {});
  }

  void downloadPaper(String paperURL) async {
    await launchUrl(Uri.parse(pdfUrlFor(paperURL)));
  }

  Future<void> openPaperDetails(Paper paper) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaperDetailPage(
          paper: paper,
          downloadPaper: downloadPaper,
          parseAndLaunchURL: parseAndLaunchURL,
          onSearchQuerySelected: runFeedSearch,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      notesRefreshToken++;
    });
  }

  Future<void> openPaperNotes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaperNotesPage(
          downloadPaper: downloadPaper,
          parseAndLaunchURL: parseAndLaunchURL,
          onSearchQuerySelected: runFeedSearch,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      notesRefreshToken++;
    });
  }

  String pdfUrlFor(String paperURL) {
    var selectedURL = paperURL.trim();
    if (selectedURL.startsWith("http") && selectedURL.contains("/pdf/")) {
      return selectedURL;
    }

    var splitURL = paperURL.split("/");
    var id = splitURL[splitURL.length - 1];
    if (id.contains(".") == true) {
      selectedURL = "$pdfBaseURL/$id";
    } else {
      selectedURL = "$pdfBaseURL/cond-mat/$id";
    }
    return selectedURL;
  }

  @override
  void initState() {
    super.initState();
    search();
  }

  @override
  void dispose() {
    searchTermController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("OpenScholarXIV"),
        actions: [
          // SETTINGS
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),

          // BOOKMARKS
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookmarksPage(
                    downloadPaper: downloadPaper,
                    parseAndLaunchURL: parseAndLaunchURL,
                    onSearchQuerySelected: runFeedSearch,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_border_outlined),
          ),

          // PAPER NOTES
          IconButton(
            onPressed: () {
              openPaperNotes();
            },
            icon: const Icon(Icons.sticky_note_2_outlined),
          ),

          // CHAT WITH AI
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIChatPage(paperData: null),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome_outlined),
          ),

          const SizedBox(width: 10.0),
        ],
      ),
      body: LiquidPullToRefresh(
        onRefresh: search,
        backgroundColor: colorScheme.surface,
        color: colorScheme.primary,
        animSpeedFactor: 2.0,
        child: ListView(
          children: [
            SearchBox(
              searchTermController: searchTermController,
              searchFunction: search,
              toggleSortOrder: toggleSortOrder,
              sortOrderNewest: sortOrderNewest,
              onCategorySelected: searchCategory,
            ),

            // Data or Loading
            isHomeScreenLoading == true
                ? const PaperFeedSkeleton()
                : homeScreenError != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: 160.0,
                      left: 24.0,
                      right: 24.0,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 42.0,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          homeScreenError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12.0),
                        TextButton(
                          onPressed: () {
                            search(resetPagination: true);
                          },
                          child: const Text("Try Again"),
                        ),
                      ],
                    ),
                  )
                : data.isNotEmpty
                ? Column(
                    children: data.map((eachPaper) {
                      return EachPaperCard(
                        eachPaper: eachPaper,
                        downloadPaper: downloadPaper,
                        parseAndLaunchURL: parseAndLaunchURL,
                        isBookmarked: false,
                        onCardTap: () => openPaperDetails(eachPaper),
                        notesRefreshToken: notesRefreshToken,
                      );
                    }).toList(),
                  )
                : const Padding(
                    padding: EdgeInsets.only(top: 200.0),
                    child: Center(child: Text("No Results Found!")),
                  ),

            const SizedBox(height: 20.0),

            // Pagination
            data.isNotEmpty && searchTermController.text.trim() != ""
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (startPagination >= paginationGap) {
                            startPagination -= paginationGap;
                            search();
                          }
                        },
                        icon: Icon(
                          Ionicons.arrow_back,
                          color: startPagination < paginationGap
                              ? colorScheme.onSurface.withAlpha(64)
                              : colorScheme.onSurfaceVariant,
                          size: 20.0,
                        ),
                      ),
                      Text(
                        "Showing results from $startPagination to ${startPagination + maxContent}",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      IconButton(
                        onPressed: () {
                          startPagination += paginationGap;
                          search();
                        },
                        icon: Icon(
                          Ionicons.arrow_forward,
                          color: colorScheme.onSurfaceVariant,
                          size: 20.0,
                        ),
                      ),
                    ],
                  )
                : Container(),

            Container(
              width: 100.0,
              padding: const EdgeInsets.only(top: 200.0, bottom: 40.0),
              child: Center(
                child: Text(
                  "Thank you to arXiv for use of its \nopen access interoperability.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse(sourceCodeURL));
                },
                child: Text(
                  "View Source Code on GitHub",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.primary, fontSize: 12.0),
                ),
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Made with 🤍 by ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        launchUrl(Uri.parse(scholarXivURL));
                      },
                      child: Text(
                        "ScholarXIV",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
