import 'package:flutter/material.dart';

enum DeviceOrientation {
  portrait,
  landscape,
}

class ResponsiveLayout extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;

  const ResponsiveLayout({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  static bool isCarScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 1024 || (size.width > size.height && size.width >= 800);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > constraints.maxHeight) {
          return landscape;
        }
        return portrait;
      },
    );
  }
}

class CarLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceOrientation orientation) builder;

  const CarLayoutBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final orientation = constraints.maxWidth > constraints.maxHeight
            ? DeviceOrientation.landscape
            : DeviceOrientation.portrait;
        return builder(context, orientation);
      },
    );
  }
}

class CarAdaptivePage extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;

  const CarAdaptivePage({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return CarLayoutBuilder(
      builder: (context, orientation) {
        if (orientation == DeviceOrientation.landscape) {
          return landscape;
        }
        return portrait;
      },
    );
  }
}

class CarScreenSize {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isExtraLarge(BuildContext context) {
    return screenWidth(context) >= 1440;
  }

  static bool isLarge(BuildContext context) {
    final width = screenWidth(context);
    return width >= 1024 && width < 1440;
  }

  static bool isMedium(BuildContext context) {
    final width = screenWidth(context);
    return width >= 600 && width < 1024;
  }

  static bool isSmall(BuildContext context) {
    return screenWidth(context) < 600;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isExtraLarge(context)) return 5;
    if (isLarge(context)) return 4;
    if (isMedium(context)) return 3;
    if (isSmall(context)) return 2;
    return 2;
  }

  static double getGridChildAspectRatio(BuildContext context, {bool isLandscape = false}) {
    if (isLandscape) {
      if (isExtraLarge(context)) return 16 / 8;
      if (isLarge(context)) return 16 / 9;
      return 16 / 10;
    }
    if (isExtraLarge(context)) return 16 / 10;
    if (isLarge(context)) return 16 / 11;
    return 16 / 12;
  }
}

class CarSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  static double horizontalPadding(BuildContext context) {
    if (CarScreenSize.isExtraLarge(context)) return 48.0;
    if (CarScreenSize.isLarge(context)) return 32.0;
    if (CarScreenSize.isMedium(context)) return 24.0;
    return 16.0;
  }

  static double verticalPadding(BuildContext context) {
    if (CarScreenSize.isExtraLarge(context)) return 32.0;
    if (CarScreenSize.isLarge(context)) return 24.0;
    if (CarScreenSize.isMedium(context)) return 20.0;
    return 16.0;
  }
}

class CarTextStyle {
  static TextStyle headlineLarge(BuildContext context) {
    final base = Theme.of(context).textTheme.headlineLarge;
    if (CarScreenSize.isSmall(context)) {
      return base!.copyWith(fontSize: 28);
    }
    return base!;
  }

  static TextStyle titleLarge(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge;
    if (CarScreenSize.isSmall(context)) {
      return base!.copyWith(fontSize: 18);
    }
    return base!;
  }

  static TextStyle bodyMedium(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    if (CarScreenSize.isSmall(context)) {
      return base!.copyWith(fontSize: 14);
    }
    return base!;
  }

  static TextStyle labelSmall(BuildContext context) {
    final base = Theme.of(context).textTheme.labelSmall;
    if (CarScreenSize.isSmall(context)) {
      return base!.copyWith(fontSize: 10);
    }
    return base!;
  }
}

class CarCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const CarCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(12);

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: card,
        ),
      );
    }

    return card;
  }
}

class CarGridView extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final int? crossAxisCount;
  final double? childAspectRatio;

  const CarGridView({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.crossAxisCount,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final count = crossAxisCount ?? CarScreenSize.getGridCrossAxisCount(context);
    final isLandscape = ResponsiveLayout.isLandscape(context);
    final aspectRatio = childAspectRatio ?? CarScreenSize.getGridChildAspectRatio(context, isLandscape: isLandscape);

    return GridView.count(
      crossAxisCount: count,
      crossAxisSpacing: spacing ?? 12,
      mainAxisSpacing: runSpacing ?? 12,
      childAspectRatio: aspectRatio,
      padding: EdgeInsets.all(CarSpacing.horizontalPadding(context)),
      children: children,
    );
  }
}

class CarListView extends StatelessWidget {
  final List<Widget> children;
  final Axis? direction;
  final EdgeInsetsGeometry? padding;
  final bool? shrinkWrap;

  const CarListView({
    super.key,
    required this.children,
    this.direction,
    this.padding,
    this.shrinkWrap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: direction ?? Axis.vertical,
      padding: padding ?? EdgeInsets.all(CarSpacing.horizontalPadding(context)),
      shrinkWrap: shrinkWrap ?? false,
      children: children,
    );
  }
}

class CarHorizontalListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;
  final bool? shrinkWrap;

  const CarHorizontalListView({
    super.key,
    required this.children,
    this.padding,
    this.itemExtent,
    this.shrinkWrap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemExtent ?? 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ?? EdgeInsets.symmetric(horizontal: CarSpacing.horizontalPadding(context)),
        shrinkWrap: shrinkWrap ?? true,
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(width: CarSpacing.md),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}
