// ignore_for_file: file_names
import 'package:arxiv/apis/arxiv.dart';
import 'package:arxiv/components/each_paper_card.dart';
import 'package:arxiv/components/loading_indicator.dart';
import 'package:arxiv/components/search_box.dart';
import 'package:arxiv/models/paper.dart';
import 'package:arxiv/pages/ai_chat_page.dart';
import 'package:arxiv/pages/bookmarks_page.dart';
import 'package:arxiv/pages/how_to_use.dart';
import 'package:arxiv/pages/pdf_viewer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ionicons/ionicons.dart';

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

  var dio = Dio();
  List<Paper> data = [];
  ArxivSearchResult? lastSearchResult;

  Future<void> search({bool? resetPagination}) async {
    if (resetPagination == true) {
      startPagination = 0;
    }
    isHomeScreenLoading = true;
    data = [];
    setState(() {});

    var searchTerm = searchTermController.text.toString().trim();
    if (searchTerm.isNotEmpty) {
      final result = await Arxiv.searchWithMetadata(
        searchTerm,
        page: startPagination,
        pageSize: maxContent,
      );
      lastSearchResult = result;
      data = result.papers;
    } else {
      final result = await suggestedPapers();
      lastSearchResult = result;
      data = result.papers;
    }

    isHomeScreenLoading = false;
    setState(() {});
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
    var maxRetries = 10;
    var suggested = const ArxivSearchResult(
      papers: [],
      feed: {},
      rawResponse: {},
      rawXml: "",
    );
    while (suggested.papers.isEmpty && maxRetries > 0) {
      suggested = await Arxiv.suggestWithMetadata(pageSize: maxContent);
      maxRetries--;
    }
    return suggested;
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ThemeProvider.themeOf(
          context,
        ).data.appBarTheme.backgroundColor,
        title: const Text("OpenScholarXIV"),
        actions: [
          // HELP
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HowToUsePage()),
              );
            },
            icon: const Icon(Icons.help_outline),
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
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_border_outlined),
          ),

          // CHANGE THEME
          IconButton(
            onPressed: () {
              ThemeProvider.controllerOf(context).nextTheme();
            },
            icon: Icon(
              ThemeProvider.themeOf(context).id == "light_theme"
                  ? Icons.dark_mode_outlined
                  : ThemeProvider.themeOf(context).id == "dark_theme"
                  ? Icons.sunny_snowing
                  : Ionicons.sunny,
            ),
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
        backgroundColor: Colors.white,
        color: const Color(0xff121212),
        animSpeedFactor: 2.0,
        child: ListView(
          children: [
            SearchBox(
              searchTermController: searchTermController,
              searchFunction: search,
              toggleSortOrder: toggleSortOrder,
              sortOrderNewest: sortOrderNewest,
            ),

            // Data or Loading
            isHomeScreenLoading == true
                ? const LoadingIndicator(topPadding: 200.0)
                : data.isNotEmpty
                ? Column(
                    children: data.map((eachPaper) {
                      return EachPaperCard(
                        eachPaper: eachPaper,
                        downloadPaper: downloadPaper,
                        parseAndLaunchURL: parseAndLaunchURL,
                        isBookmarked: false,
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
                              ? Colors.white
                              : Colors.grey[400]!,
                          size: 20.0,
                        ),
                      ),
                      Text(
                        "Showing results from $startPagination to ${startPagination + maxContent}",
                        style: TextStyle(color: Colors.grey[600]!),
                      ),
                      IconButton(
                        onPressed: () {
                          startPagination += paginationGap;
                          search();
                        },
                        icon: Icon(
                          Ionicons.arrow_forward,
                          color: Colors.grey[400]!,
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
                  style: TextStyle(color: Colors.grey[400]!, fontSize: 12.0),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse(sourceCodeURL));
                },
                child: const Text(
                  "View Source Code on GitHub",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueAccent, fontSize: 12.0),
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
                        color: Colors.grey[600]!,
                        fontSize: 12.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        launchUrl(Uri.parse(scholarXivURL));
                      },
                      child: const Text(
                        "ScholarXIV",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueAccent,
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
