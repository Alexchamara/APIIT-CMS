import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:apiit_cms/shared/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarStyles.primary(
        title: 'APIIT CMS',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthRepository.signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 100, color: AppTheme.primary),
            SizedBox(height: 20),
            Text('Welcome to APIIT CMS', style: AppTheme.headlineMedium),
            SizedBox(height: 10),
            Text('Seamless Classroom Management', style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
