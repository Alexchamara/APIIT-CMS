# Analytics Feature

## Overview

The Analytics feature provides comprehensive insights and statistics about the APIIT CMS system usage for administrators. It presents data about classrooms, reservations, and users in an easy-to-understand visual format.

## Features

### Admin-Only Access
- Analytics tab is only visible to users with admin privileges
- Non-admin users do not see the Analytics option in navigation

### Three Main Categories

#### 1. Classroom Analytics
- **Overview**: Total, available, unavailable, and maintenance classroom counts
- **Capacity Information**: Total and average capacity across all classrooms
- **Availability Rate**: Percentage of classrooms currently available
- **Distribution**: Breakdown by classroom type (Lab, Classroom, Auditorium) and floor

#### 2. Reservation Analytics
- **Overview**: Total, approved, pending, and cancelled reservation counts
- **Performance Metrics**: Approval rate and cancellation rate percentages
- **Activity**: Average reservations per day (last 30 days)
- **Distribution**: 
  - Reservations by type (Lecture, Meeting, Exam, etc.)
  - Most booked classrooms (top 5)
  - Most active lecturers (top 5)

#### 3. User Analytics
- **Overview**: Total users, administrators, lecturers, and active users
- **User Distribution**: Percentage breakdown of admin vs lecturer users
- **Activity Rate**: Percentage of active vs inactive users
- **Activity Leader**: Most active user by number of reservations

## Architecture

### Domain Layer
- **Models**: `AnalyticsData`, `ClassroomAnalytics`, `ReservationAnalytics`, `UserAnalytics`
- Contains all data structures and business logic for analytics calculations

### Data Layer
- **Repository**: `AnalyticsRepository` - Fetches and processes data from Firestore
- Aggregates data from multiple collections (classrooms, reservations, users)
- Calculates percentages, averages, and statistical insights

### Presentation Layer
- **Screen**: `AnalyticsScreen` - Main analytics interface with tabbed layout
- **Widgets**: 
  - `StatCard` - Display numerical statistics
  - `PercentageCard` - Show percentage-based metrics with progress bars
  - `TopItemsList` - Display ranked lists of items

## UI Design

### Layout Structure
- **Tab Navigation**: Three tabs for Classrooms, Reservations, and Users
- **Card-Based Layout**: Clean, organized cards displaying different metrics
- **Responsive Grid**: 2-column grid for overview statistics
- **Visual Indicators**: Progress bars for percentages and color-coded status

### Color Scheme
- **Primary**: Teal (#00B2A7) for main analytics
- **Success**: Green for positive metrics (available, approved)
- **Error**: Red for negative metrics (unavailable, cancelled)
- **Warning**: Orange for maintenance and pending items
- **Secondary**: Gray for neutral information

### Visual Elements
- **Icons**: Contextual icons for each metric type
- **Progress Bars**: Visual representation of percentages
- **Cards**: Consistent card design with shadows and borders
- **Charts**: Top items lists with badge-style counts

## Data Sources

### Classroom Data
- Fetched from `classrooms` Firestore collection
- Processes availability status, maintenance periods, capacity, type, and floor data

### Reservation Data
- Fetched from `reservations` Firestore collection
- Analyzes approval status, reservation types, classroom usage patterns, and lecturer activity

### User Data
- Fetched from `users` Firestore collection
- Examines user types, activity status, and registration patterns

## Real-time Updates

- **Pull-to-Refresh**: Users can refresh data by pulling down or using refresh button
- **Error Handling**: Graceful error handling with retry options
- **Loading States**: Clear loading indicators during data fetching

## Performance Considerations

- **Parallel Data Fetching**: All three analytics categories are fetched simultaneously
- **Efficient Calculations**: Optimized algorithms for statistical calculations
- **Memory Management**: Proper disposal of resources and controllers

## Usage

### For Administrators
1. Navigate to the "Analytics" tab in the bottom navigation (admin-only)
2. View three categories: Classrooms, Reservations, and Users
3. Swipe between tabs or tap tab titles to switch categories
4. Pull down to refresh data or use the refresh button
5. Scroll through different metrics and insights

### Key Metrics to Monitor
- **Classroom utilization rates**
- **Reservation approval patterns**
- **User engagement levels**
- **Resource distribution and availability**

## Future Enhancements

- **Time-based Analytics**: Historical trends and patterns
- **Export Functionality**: Export reports as PDF or CSV
- **Chart Visualizations**: Interactive charts and graphs
- **Alerts**: Notifications for unusual patterns or thresholds
- **Detailed Filtering**: Date ranges and specific criteria filtering

## Dependencies

- `flutter`: UI framework
- `cloud_firestore`: Database operations for analytics data
- Built on existing models from classroom, reservation, and user features

## Files Structure

```
lib/features/analytics/
├── domain/
│   └── models/
│       └── analytics_data.dart
├── data/
│   └── analytics_repository.dart
└── presentation/
    ├── screens/
    │   └── analytics_screen.dart
    └── widgets/
        └── analytics_widgets.dart
```

## Technical Notes

- Uses existing authentication system to verify admin privileges
- Leverages established design system and theme constants
- Integrates seamlessly with existing navigation structure
- Follows clean architecture principles used throughout the application
