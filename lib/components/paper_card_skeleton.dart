import 'package:arxiv/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PaperFeedSkeleton extends StatelessWidget {
  const PaperFeedSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (_) => const PaperCardSkeleton()),
    );
  }
}

class PaperCardSkeleton extends StatefulWidget {
  const PaperCardSkeleton({super.key});

  @override
  State<PaperCardSkeleton> createState() => _PaperCardSkeletonState();
}

class _PaperCardSkeletonState extends State<PaperCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = subtleSurfaceColor(colorScheme);
    final baseColor = colorScheme.onSurfaceVariant.withAlpha(30);
    final highlightColor = colorScheme.onSurfaceVariant.withAlpha(58);

    return Container(
      margin: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        bottom: 6.0,
        top: 6.0,
      ),
      padding: const EdgeInsets.only(
        left: 10.0,
        right: 10.0,
        top: 6.0,
        bottom: 6.0,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return _SkeletonTheme(
            shimmerValue: _controller.value,
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: child!,
          );
        },
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 2.0, right: 5.0),
              child: Wrap(
                spacing: 10.0,
                runSpacing: 2.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _SkeletonBar(width: 88.0, height: 12.0),
                  _SkeletonBar(width: 120.0, height: 12.0),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBar(widthFactor: 0.92, height: 18.0),
                  SizedBox(height: 6.0),
                  _SkeletonBar(widthFactor: 0.66, height: 18.0),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 2.0),
              child: _SkeletonBar(width: 154.0, height: 12.0),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: _SkeletonBar(widthFactor: 0.74, height: 13.0),
            ),
            Row(
              children: [
                Expanded(child: _SkeletonBar(height: 34.0, borderRadius: 20.0)),
                SizedBox(width: 10.0),
                _SkeletonIcon(),
                _SkeletonIcon(),
                _SkeletonIcon(),
                _SkeletonIcon(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonTheme extends InheritedWidget {
  const _SkeletonTheme({
    required this.shimmerValue,
    required this.baseColor,
    required this.highlightColor,
    required super.child,
  });

  final double shimmerValue;
  final Color baseColor;
  final Color highlightColor;

  static _SkeletonTheme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SkeletonTheme>()!;
  }

  @override
  bool updateShouldNotify(_SkeletonTheme oldWidget) {
    return shimmerValue != oldWidget.shimmerValue ||
        baseColor != oldWidget.baseColor ||
        highlightColor != oldWidget.highlightColor;
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    this.width,
    this.widthFactor,
    required this.height,
    this.borderRadius = 6.0,
  });

  final double? width;
  final double? widthFactor;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final bar = _ShimmerBox(height: height, borderRadius: borderRadius);

    if (widthFactor != null) {
      return FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: bar,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: bar);
    }

    return bar;
  }
}

class _SkeletonIcon extends StatelessWidget {
  const _SkeletonIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 48.0,
      height: 48.0,
      child: Center(
        child: SizedBox(
          width: 24.0,
          height: 24.0,
          child: _ShimmerBox(borderRadius: 12.0),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.height, required this.borderRadius});

  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final skeletonTheme = _SkeletonTheme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 0.5, 1.0],
          colors: [
            skeletonTheme.baseColor,
            skeletonTheme.highlightColor,
            skeletonTheme.baseColor,
          ],
          transform: _SlidingGradientTransform(skeletonTheme.shimmerValue),
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.value);

  final double value;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * ((value * 2) - 1),
      0.0,
      0.0,
    );
  }
}
