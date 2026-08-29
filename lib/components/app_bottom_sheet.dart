import 'package:flutter/material.dart';

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
  bool showDragHandle = true,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    clipBehavior: Clip.antiAlias,
    builder: (context) => child,
  );
}

/// Shared header + scrollable body layout for modal bottom sheets.
class AppBottomSheetShell extends StatelessWidget {
  const AppBottomSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.onClose,
    this.maxHeightFactor = 0.72,
    this.titleTextStyle,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final double maxHeightFactor;
  final TextStyle? titleTextStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 4.0, 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style:
                            titleTextStyle ??
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                      ),
                    ),
                    ...actions,
                    IconButton(
                      tooltip: "Close",
                      onPressed: onClose ?? () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ClipRect(
                  // Stop list content from painting over the title row while scrolling.
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
