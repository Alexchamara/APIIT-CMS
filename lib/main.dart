import 'package:apiit_cms/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:apiit_cms/firebase_options.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:apiit_cms/shared/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize notification service
  await NotificationService.initialize();
  NotificationService.handleForegroundNotification();
  NotificationService.handleNotificationTap();
  await NotificationService.handleInitialNotification();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APIIT CMS',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
