import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Local Imports
import 'theme.dart';
import 'localization.dart';
import 'api_service.dart';
import 'screens.dart';

void main() {
  // Ensure bindings are initialized before rendering, crucial for SharedPreferences on web
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLocale()),
        ChangeNotifierProvider(create: (_) => UniBridgeApi()),
      ],
      child: const UniBridgeWebApp(),
    ),
  );
}

class UniBridgeWebApp extends StatelessWidget {
  const UniBridgeWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes in localization to rebuild the app when language changes
    final appLocale = Provider.of<AppLocale>(context);

    return MaterialApp(
      title: 'UniBridge Web System',
      debugShowCheckedModeBanner: false, // Hides the debug banner for a cleaner UI
      theme: TechTheme.darkTheme,
      
      // Localization Setup
      locale: appLocale.locale,
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('ar', ''), // Arabic
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Locale fallback mechanism
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first; // Default to English
      },
      
      // Application Entry Point
      home: const SplashScreen(),
    );
  }
}