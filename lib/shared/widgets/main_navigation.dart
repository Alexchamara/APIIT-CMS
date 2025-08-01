import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/home/presentation/screens/home_screen.dart';
import 'package:apiit_cms/features/profile/presentation/screens/profile_screen.dart';
import 'package:apiit_cms/features/users/presentation/screens/user_management_screen.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await AuthRepository.getCurrentUserModel();
    setState(() {
      _isLoading = false;
    });
  }

  bool get _isAdmin => _currentUser?.userType == UserType.admin;

  List<Widget> get _pages {
    if (_isAdmin) {
      return [
        const HomeScreen(),
        const Center(child: Text('Classes')),
        const UserManagementScreen(),
        const ProfileScreen(),
      ];
    } else {
      return [
        const HomeScreen(),
        const Center(child: Text('Classes')),
        const ProfileScreen(),
      ];
    }
  }

  List<NavigationDestination> get _destinations {
    final baseDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        label: 'Home',
      ),
      const NavigationDestination(icon: Icon(Icons.desk), label: 'Classes'),
    ];

    if (_isAdmin) {
      baseDestinations.add(
        const NavigationDestination(
          icon: Icon(Icons.people_alt_outlined),
          label: 'Users',
        ),
      );
    }

    baseDestinations.add(
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        label: 'Me',
      ),
    );

    return baseDestinations;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
            _pageController.jumpToPage(_currentIndex);
          });
        },
        destinations: _destinations,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
    );
  }
}
