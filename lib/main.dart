import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'pages/home_page.dart';
import 'repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(Repo(prefs));
  runApp(DevedoresApp(appState: appState));
}

class DevedoresApp extends StatelessWidget {
  final AppState appState;
  const DevedoresApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Devedores',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.brown, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: appState.themeMode,
          home: HomePage(app: appState),
        );
      },
    );
  }
}
