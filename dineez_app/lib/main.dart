import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'config/constants.dart';
import 'config/routes.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    ProviderScope(
      overrides: [
        // We could add any provider overrides here if needed
      ],
      child: const DineEZApp(),
    ),
  );
}

class DineEZApp extends ConsumerStatefulWidget {
  const DineEZApp({super.key});

  @override
  ConsumerState<DineEZApp> createState() => _DineEZAppState();
}

class _DineEZAppState extends ConsumerState<DineEZApp> {
  @override
  void initState() {
    super.initState();
    
    // Initialize app preferences
    Future.delayed(Duration.zero, () {
      // Log app startup
      ref.read(logInfoProvider)('App started', source: 'main');
      
      // Check network status
      ref.read(networkProvider.notifier).checkConnectivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for theme changes
    final themeState = ref.watch(themeProvider);
    
    // Watch for network connectivity
    final isOnline = ref.watch(isOnlineProvider);
    
    // Show a banner if offline
    final offlineBanner = isOnline ? null : MaterialBanner(
      content: const Text('You are currently offline. Some features may not be available.'),
      leading: const Icon(Icons.wifi_off),
      backgroundColor: Colors.amber,
      actions: [
        TextButton(
          onPressed: () => ref.read(networkProvider.notifier).checkConnectivity(),
          child: const Text('RETRY'),
        ),
      ],
    );
    
    // Watch for global loading state and error messages
    final isLoading = ref.watch(globalLoadingProvider);
    final globalError = ref.watch(globalErrorProvider);
    
    return MaterialApp(
      title: AppConstants.appName,
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      themeMode: themeState.themeMode,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppConstants.routeInitial,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Add global loading indicator and error handling
        Widget currentChild = child ?? const SizedBox.shrink();
        
        // Show offline banner if needed
        if (offlineBanner != null) {
          currentChild = Banner(
            message: 'Offline',
            location: BannerLocation.topStart,
            color: Colors.red,
            child: currentChild,
          );
        }
        
        // Show global error message if any
        if (globalError != null) {
          currentChild = Stack(
            children: [
              currentChild,
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  child: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      globalError,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        
        // Show global loading indicator if needed
        if (isLoading) {
          currentChild = Stack(
            children: [
              currentChild,
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          );
        }
        
        return currentChild;
      },
    );
  }
}
