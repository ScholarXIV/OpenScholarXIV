// ignore_for_file: file_names
import 'package:arxiv/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({
    super.key,
    required this.searchTermController,
    required this.searchFunction,
    required this.toggleSortOrder,
    required this.sortOrderNewest,
  });

  final TextEditingController searchTermController;
  final Function searchFunction;
  final Function toggleSortOrder;
  final bool sortOrderNewest;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  @override
  void initState() {
    super.initState();
    widget.searchTermController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void clearSearchQuery() {
    widget.searchTermController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(color: colorScheme.surface),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 18.0, right: 18.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                color: subtleSurfaceColor(colorScheme),
              ),
              child: TextField(
                controller: widget.searchTermController,
                keyboardType: TextInputType.url,
                cursorColor: colorScheme.primary,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                  suffixIcon: widget.searchTermController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            clearSearchQuery();
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
                onSubmitted: (searchTerm) {
                  widget.searchFunction(resetPagination: true);
                },
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              widget.toggleSortOrder();
            },
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: () {
              widget.searchFunction(resetPagination: true);
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}
