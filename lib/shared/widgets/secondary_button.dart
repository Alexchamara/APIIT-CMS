import 'package:apiit_cms/shared/theme.dart';
import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isUnderlined;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isUnderlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textSecondary,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: AppTheme.linkText.copyWith(
          decoration: isUnderlined ? TextDecoration.underline : null,
          decorationThickness: isUnderlined ? 1.5 : null,
        ),
      ),
    );
  }
}
