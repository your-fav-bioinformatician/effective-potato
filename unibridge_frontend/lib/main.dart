import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme.dart'; // Contains TechTheme
import 'localization.dart';
import 'api_service.dart';
import 'screens.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLocale()),
        Provider(create: (_) => UniBridgeApi()),
      ],
      child: const UniBridgeApp(),
    ),
  );
}

class UniBridgeApp extends StatelessWidget {
  const UniBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocale = Provider.of<AppLocale>(context);

    return MaterialApp(
      title: 'UniBridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Updated to use TechTheme
        primaryColor: TechTheme.primaryBlue,
        scaffoldBackgroundColor: TechTheme.backgroundGrey,
        textTheme: TechTheme.textTheme,
        useMaterial3: true,
        // Optional: Add color scheme for better widget defaults
        colorScheme: ColorScheme.fromSeed(
          seedColor: TechTheme.primaryBlue,
          primary: TechTheme.primaryBlue,
          background: TechTheme.backgroundGrey,
        ),
      ),
      locale: appLocale.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}