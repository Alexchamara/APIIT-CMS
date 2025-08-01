# User Management Feature

## Overview
This feature provides a comprehensive user management system for the APIIT CMS application. It allows administrators to view, create, and manage users (both admins and lecturers) in the system.

## Architecture

The feature follows Clean Architecture principles with separation of concerns:

### Domain Layer
- **Models**: `UserFilter` enum for filtering users
- **Repositories**: `UserRepository` interface defining contract for user operations
- **Use Cases**: Individual use cases for specific operations
  - `GetAllUsersUseCase`
  - `GetUsersStreamUseCase`
  - `UpdateUserUseCase`
  - `DeleteUserUseCase`
  - `CreateUserUseCase`

### Data Layer
- **Repository Implementation**: `UserRepositoryImpl` - Firebase Firestore implementation
- **Features**: 
  - Real-time user stream
  - User creation with temporary password
  - User updates
  - User deactivation (soft delete)

### Presentation Layer
- **Cubit**: `UserManagementCubit` - State management using BLoC pattern
- **States**: Comprehensive state management for loading, error, and data states
- **Screens**: `UserManagementScreen` - Main user interface
- **Widgets**: 
  - `UserListItem` - Individual user display
  - `AddUserDialog` - User creation form

## Features

### Admin-Only Access
- User management screen is only accessible to users with admin privileges
- Navigation tab is conditionally shown based on user role
- Non-admin users see an access denied message

### User Filtering
- **Admins Tab**: Shows only admin users
- **Lecturers Tab**: Shows only lecturer users
- Real-time filtering without additional network requests

### Search Functionality
- Search by user name or email
- Real-time search results
- Case-insensitive search

### User Display
- Profile pictures with fallback to initials
- User type badges (Admin/Lecturer)
- Clean, modern UI following design guidelines

### User Creation
- Modal dialog for adding new users
- Form validation for email and name
- User type selection (Admin/Lecturer)
- Optional phone number field
- Automatic password reset email sent to new users

### Real-time Updates
- Live updates when users are added, modified, or removed
- Stream-based architecture ensures UI stays in sync

## UI Design

The user management screen follows the design from "user management.png":

- **Header**: Large "Users" title
- **Search Bar**: Rounded search input with search icon
- **Filter Tabs**: "Admins" and "Lecturers" pills with selection state
- **User List**: Clean list items with:
  - Profile pictures/initials in circles
  - Name and email display
  - User type badges
- **Floating Action Button**: "Add new user" with person icon

### Color Scheme
- Primary: Teal (#00B2A7)
- Background: White
- Text: Dark gray
- Secondary text: Light gray
- Selected states: Primary color

## Usage

### For Administrators
1. Navigate to the "Users" tab in the bottom navigation
2. View list of users filtered by type (Admins/Lecturers)
3. Search for specific users using the search bar
4. Tap "Add new user" to create new accounts
5. Fill in user details and select user type
6. New users receive password reset emails to set their passwords

### For Lecturers
- Users tab is not visible in navigation
- Attempting to access user management shows access denied

## Security

### Access Control
- Server-side user type validation
- UI-level access restrictions
- Firebase Auth integration

### User Creation
- Temporary passwords for new accounts
- Immediate password reset email dispatch
- Email verification workflow

## Dependencies

- `flutter_bloc`: State management
- `equatable`: Value equality for states
- `firebase_auth`: Authentication
- `cloud_firestore`: Database operations

## Future Enhancements

1. **User Details/Edit Dialog**: Comprehensive user editing
2. **Bulk Operations**: Multi-select and bulk actions
3. **User Roles**: Extended role system beyond admin/lecturer
4. **User Permissions**: Granular permission management
5. **Export Functionality**: Export user lists to CSV/Excel
6. **Advanced Filtering**: Filter by creation date, status, etc.
7. **User Profile Management**: Extended profile fields
8. **Activity Logging**: Track user management actions

## Error Handling

- Network error recovery with retry functionality
- Form validation with user-friendly messages
- Toast notifications for success/error states
- Loading states during operations

## Performance Considerations

- Stream-based real-time updates
- Client-side filtering to reduce network requests
- Efficient list rendering with ListView.builder
- Proper disposal of resources and streams
