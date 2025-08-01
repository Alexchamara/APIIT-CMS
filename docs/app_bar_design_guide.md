# Consistent App Bar Design Guide

This document outlines the standardized app bar design implementation for the APIIT CMS application to ensure a consistent look and feel across all screens.

## Overview

The `CustomAppBar` widget and `AppBarStyles` utility class provide a consistent app bar design pattern that should be used across all screens in the application.

## Implementation

### CustomAppBar Widget

Location: `lib/shared/widgets/custom_app_bar.dart`

The `CustomAppBar` widget provides a flexible, reusable app bar with consistent styling:

```dart
CustomAppBar(
  title: 'Screen Title',
  actions: [/* optional action widgets */],
  showBackButton: true, // default
  backgroundColor: AppTheme.primary, // default
  foregroundColor: AppTheme.white, // default
)
```

### Pre-defined Styles

The `AppBarStyles` class provides three pre-configured app bar styles:

#### 1. Primary Style (Default)
- Background: `AppTheme.primary` (teal)
- Foreground: `AppTheme.white`
- Elevation: 0
- Best for: Main screens, navigation screens

```dart
AppBarStyles.primary(
  title: 'Classrooms',
  showBackButton: false, // for main navigation screens
)
```

#### 2. Light Style
- Background: `AppTheme.white`
- Foreground: `AppTheme.textPrimary`
- Elevation: 1
- Best for: Detail screens, forms, profile screens

```dart
AppBarStyles.light(
  title: 'Edit Profile',
  actions: [editButton],
)
```

#### 3. Transparent Style
- Background: `Colors.transparent`
- Foreground: `AppTheme.textPrimary`
- Elevation: 0
- Best for: Special cases, overlay screens

```dart
AppBarStyles.transparent(
  title: 'Special Screen',
)
```

## Current Implementation

All screens have been updated to use the consistent app bar pattern:

### Main Navigation Screens (Primary Style)
- **Home Screen**: `AppBarStyles.primary()` with logout action
- **Classrooms Screen**: `AppBarStyles.primary()` without back button
- **User Management Screen**: `AppBarStyles.primary()` without back button

### Detail/Form Screens (Light Style)
- **Profile Screen**: `AppBarStyles.light()` with edit action
- **Add User Screen**: `AppBarStyles.light()` with back button
- **User Edit Screen**: `AppBarStyles.light()` with edit action

### Action Screens (Primary Style)
- **Add Classroom Screen**: `AppBarStyles.primary()` with loading indicator
- **Access Denied Screen**: `AppBarStyles.primary()` for error states

## Design Principles

1. **Consistency**: All app bars follow the same design language
2. **Hierarchy**: Different styles indicate different screen types
3. **Accessibility**: Proper contrast ratios and touch targets
4. **Responsiveness**: Works across different device sizes

## Features

- **Automatic Back Button**: Shows when navigation stack allows
- **Custom Actions**: Support for action buttons (edit, save, etc.)
- **Loading States**: Built-in support for loading indicators
- **System UI**: Proper status bar styling
- **Flexible Theming**: Easy to customize colors and elevation

## Usage Guidelines

### Do's
- Use `AppBarStyles.primary()` for main navigation screens
- Use `AppBarStyles.light()` for detail and form screens
- Set `showBackButton: false` for main navigation screens
- Include relevant actions (edit, save, etc.) when needed
- Use loading indicators for async operations

### Don'ts
- Don't mix different app bar styles inconsistently
- Don't create custom app bars unless absolutely necessary
- Don't ignore elevation guidelines (primary: 0, light: 1)
- Don't forget to import the custom app bar widget

## Import

To use the consistent app bar in your screens:

```dart
import 'package:apiit_cms/shared/widgets/custom_app_bar.dart';
// or use the barrel export
import 'package:apiit_cms/shared/widgets.dart';
```

## Benefits

1. **Consistent User Experience**: Users get familiar with the navigation pattern
2. **Maintainable Code**: Changes to app bar styling can be made in one place
3. **Developer Efficiency**: No need to recreate app bar styling for each screen
4. **Design System**: Part of a larger design system approach
5. **Accessibility**: Built-in accessibility features and proper contrast

## Future Enhancements

- Support for search bars in app bar
- Gradient backgrounds
- Custom leading widgets
- Animation support
- Bottom app bar variants
