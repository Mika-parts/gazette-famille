import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/colors.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/famille/join_famille_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('fr_FR', null);
  runApp(const GazetteFamilleApp());
}

class GazetteFamilleApp extends StatefulWidget {
  const GazetteFamilleApp({super.key});

  @override
  State<GazetteFamilleApp> createState() => _GazetteFamilleAppState();
}

class _GazetteFamilleAppState extends State<GazetteFamilleApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // gazette://invite/{familleId}
    // https://gazette.cenaia-labs.com/invite/{familleId}
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'invite') {
      final familleId = uri.pathSegments[1];
      _navKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => JoinFamilleScreen(familleId: familleId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Gazette Famille',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('fr', 'FR'),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.data == null) return const LoginScreen();
          return const HomeScreen();
        },
      ),
    );
  }
}
