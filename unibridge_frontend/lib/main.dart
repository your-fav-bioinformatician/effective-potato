import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme.dart'; // Contains the new Cyberpunk TechTheme
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
        // Updated to use the new Cyberpunk TechTheme
        primaryColor: TechTheme.neonMagenta,
        scaffoldBackgroundColor: TechTheme.deepPurpleBG,
        textTheme: TechTheme.textTheme,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TechTheme.neonMagenta,
          primary: TechTheme.neonMagenta,
          surface: TechTheme.deepPurpleBG,
          onSurface: TechTheme.readableWhite,
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