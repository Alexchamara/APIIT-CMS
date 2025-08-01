enum UserFilter { all, admins, lecturers }

extension UserFilterExtension on UserFilter {
  String get displayName {
    switch (this) {
      case UserFilter.all:
        return 'All';
      case UserFilter.admins:
        return 'Admins';
      case UserFilter.lecturers:
        return 'Lecturers';
    }
  }
}
