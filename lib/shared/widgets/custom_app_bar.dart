import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apiit_cms/shared/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTheme.headlineMedium.copyWith(
          color: foregroundColor ?? AppTheme.white,
          fontSize: 20,
        ),
      ),
      backgroundColor: backgroundColor ?? AppTheme.primary,
      foregroundColor: foregroundColor ?? AppTheme.white,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      leading:
          leading ??
          (showBackButton && Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                )
              : null),
      actions: actions,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Pre-defined app bar styles for common use cases
class AppBarStyles {
  // Primary app bar (default style)
  static CustomAppBar primary({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
    bool centerTitle = false,
  }) {
    return CustomAppBar(
      title: title,
      actions: actions,
      leading: leading,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      backgroundColor: AppTheme.primary,
      foregroundColor: AppTheme.white,
      elevation: 0,
      centerTitle: centerTitle,
    );
  }

  // Light app bar for screens with light backgrounds
  static CustomAppBar light({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
    bool centerTitle = false,
  }) {
    return CustomAppBar(
      title: title,
      actions: actions,
      leading: leading,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      backgroundColor: AppTheme.white,
      foregroundColor: AppTheme.textPrimary,
      elevation: 1,
      centerTitle: centerTitle,
    );
  }

  // Transparent app bar for special cases
  static CustomAppBar transparent({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
    bool centerTitle = false,
  }) {
    return CustomAppBar(
      title: title,
      actions: actions,
      leading: leading,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      backgroundColor: Colors.transparent,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      centerTitle: centerTitle,
    );
  }
}
