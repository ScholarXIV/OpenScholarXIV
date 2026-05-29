import "package:arxiv/models/bookmarks.dart";
import "package:arxiv/models/chat_message.dart";
import "package:arxiv/models/chat_thread.dart";
import "package:arxiv/models/paper.dart";
import "package:arxiv/pages/home_page.dart";
import "package:arxiv/theme/app_theme.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:theme_provider/theme_provider.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(BookmarkAdapter());
  Hive.registerAdapter(PaperAdapter());
  Hive.registerAdapter(RoleAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ChatThreadAdapter());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => ThemeProvider(
        defaultThemeId: "light_theme",
        saveThemesOnChange: true,
        loadThemeOnInit: true,
        themes: buildAppThemes(lightDynamic, darkDynamic),
        child: Builder(
          builder: (themeContext) {
            final theme = ThemeProvider.themeOf(themeContext).data;
            final colorScheme = theme.colorScheme;
            final isDark = colorScheme.brightness == Brightness.dark;
            final overlayIconBrightness = isDark
                ? Brightness.light
                : Brightness.dark;

            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: overlayIconBrightness,
                statusBarBrightness: isDark
                    ? Brightness.dark
                    : Brightness.light,
                systemNavigationBarColor: colorScheme.surface,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: overlayIconBrightness,
              ),
            );

            return MaterialApp(
              theme: theme,
              debugShowCheckedModeBanner: false,
              initialRoute: "/",
              routes: {"/": (context) => const HomePage()},
              // routes: {"/": (context) => const SplashScreen()},
            );
          },
        ),
      ),
    );
  }
}
