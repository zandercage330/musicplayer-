import 'package:flutter/material.dart';
import 'package:musify/providers/music_library_provider.dart';
import 'package:musify/providers/notification_provider.dart';
import 'package:musify/providers/theme_provider.dart';
import 'package:musify/providers/profile_provider.dart';
import 'package:musify/screens/main_screen.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:musify/services/audio_player_service.dart';
import 'package:musify/services/permission_service.dart';
import 'package:musify/screens/permission_screen.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioPlayerService().init();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.musify.channel.audio',
    androidNotificationChannelName: 'Musify Audio Playback',
    androidNotificationOngoing: true,
    // androidNotificationIcon: 'mipmap/ic_launcher', // Optional: specify custom icon for small notification icon
    // notificationColor: const Color(0xFF34D1BF), // Optional: to set accent color of notification
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        Provider<AudioPlayerService>.value(value: AudioPlayerService()),
        ChangeNotifierProvider(create: (_) => MusicLibraryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkInitialPermission();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _checkInitialPermission() async {
    // Determine current status based on Android version internally handled by service for request,
    // but for initial check, we can query both relevant permissions.
    PermissionStatus initialStatus;
    // A simplified check: if audio permission is granted, assume it covers needs (for API 33+).
    // Otherwise, check storage permission. PermissionService.determinePermissionRequestUIAction will do the more detailed check.
    if (await Permission.audio.status.isGranted) {
      // Check audio for API 33+
      initialStatus = await Permission.audio.status;
    } else {
      // Fallback or for older APIs
      initialStatus = await Permission.storage.status;
    }

    if (initialStatus.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
      _initializeLibrary();
    } else {
      // If not immediately granted, also check our persisted flag from previous explicit grants.
      // This helps if the live status check is sometimes slow or inconsistent on app start.
      bool previouslyGranted =
          await _permissionService.hasStoragePermissionBeenGrantedPreviously();
      if (previouslyGranted) {
        setState(() {
          _hasPermission = true;
          _isCheckingPermission = false;
        });
        _initializeLibrary();
      } else {
        setState(() {
          _isCheckingPermission =
              false; // No permission, go to PermissionScreen
        });
      }
    }
  }

  void _initializeLibrary() {
    // Access the provider and call initializeLibrary once the first frame is drawn
    // This ensures context is available and mounted for potential SnackBars from ErrorHandler
    // Ensure this is called only AFTER permissions are confirmed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hasPermission) {
        // Ensure widget is still in the tree and permission is granted
        Provider.of<MusicLibraryProvider>(
          context,
          listen: false,
        ).initializeLibrary(context: context);
      }
    });
  }

  void _onPermissionGrantedByUser() {
    setState(() {
      _hasPermission = true;
    });
    _initializeLibrary();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioPlayerService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeProvider for theme changes
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Musify',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light().copyWith(
        colorScheme: ThemeData.light().colorScheme.copyWith(
          primary: themeProvider.accentColor,
          secondary: themeProvider.accentColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: themeProvider.accentColor,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ThemeData.dark().colorScheme.copyWith(
          primary: themeProvider.accentColor,
          secondary: themeProvider.accentColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          elevation: 0,
        ),
      ),
      home:
          _isCheckingPermission
              ? const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ) // Show loading while checking
              : _hasPermission
              ? const MainScreen()
              : PermissionScreen(
                onPermissionGranted: _onPermissionGrantedByUser,
              ),
    );
  }
}
