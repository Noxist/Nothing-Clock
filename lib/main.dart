import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_display_mode/flutter_display_mode.dart'; // Import this

import 'theme/theme.dart';
import 'screens/router.dart';
import 'providers/theme_provider.dart';
import 'providers/clock_provider.dart';
import 'providers/page_provider.dart';
import 'providers/stopwatch_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/worldclocks_provider.dart';
import 'view_models/alarms_view_model.dart';
import 'models/alarm.dart';
// Import other necessary models if Hive requires adapters

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Hive
  await Hive.initFlutter();
  // Register Adapters here if not already done (e.g., Hive.registerAdapter(AlarmAdapter()));
  
  // 2. Enable High Refresh Rate for Pixel 9 Pro XL
  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint("Error setting high refresh rate: $e");
    }
  }

  // 3. Set System UI Overlay Style (Transparent status bar)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PageProvider()),
        ChangeNotifierProvider(create: (_) => ClockProvider()),
        ChangeNotifierProvider(create: (_) => StopwatchProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => WorldClocksProvider()),
        ChangeNotifierProvider(create: (_) => AlarmsViewModel()),
      ],
      child: const NothingClockApp(),
    ),
  );
}

class NothingClockApp extends StatelessWidget {
  const NothingClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Nothing Clock',
          debugShowCheckedModeBanner: false,
          theme: NothingTheme.lightTheme,
          darkTheme: NothingTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
