import 'package:flutter/material.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackmol7/screens/splash.dart';
import 'package:hackmol7/services/notification_service.dart';
import 'package:hackmol7/ui/apptheme.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'providers/quest_provider.dart';

//import 'screens/main_navigation_screen.dart'; // Your Bottom Nav wrapper
void main() async {
  // 1. Ensure Flutter bindings are ready for SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");
  final questProvider = QuestProvider();
  tz.initializeTimeZones();

  // 3. Initialize your Notification Service
  final notificationService = NotificationService();
  await notificationService.init();
  // 2. IMPORTANT: Load user data and the Map API before the app starts
  // This ensures provider.currentChapter is NOT null when HomeScreen builds
  try {
    await questProvider.loadUserData();
  } catch (e) {
    debugPrint("Startup Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: questProvider)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodeQuest',
      theme: AppTheme.darkTheme,
      // 3. Using a Consumer ensures that if data loads late, the UI updates
      home: Consumer<QuestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.cyan),
              ),
            );
          }
          return const SplashScreen();
        },
      ),
    );
  }
}
