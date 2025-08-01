import 'package:flutter/material.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/users/data/repositories/user_repository_impl.dart';
import 'package:apiit_cms/shared/theme.dart';

class UserDropdownSearch extends StatefulWidget {
  final UserModel? selectedUser;
  final Function(UserModel?) onUserSelected;
  final String? labelText;
  final String? hintText;
  final List<UserType>? filterByUserTypes;
  final bool isRequired;
  final String? Function(UserModel?)? validator;

  const UserDropdownSearch({
    super.key,
    required this.selectedUser,
    required this.onUserSelected,
    this.labelText = 'Select User',
    this.hintText = 'Search and select user...',
    this.filterByUserTypes,
    this.isRequired = false,
    this.validator,
  });

  @override
  State<UserDropdownSearch> createState() => _UserDropdownSearchState();
}

class _UserDropdownSearchState extends State<UserDropdownSearch> {
  final TextEditingController _searchController = TextEditingController();
  final UserRepositoryImpl _userRepository = UserRepositoryImpl();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);

    // Set initial search text if user is already selected
    if (widget.selectedUser != null) {
      _searchController.text = widget.selectedUser!.displayName;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(UserDropdownSearch oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update search text if selected user changes externally
    if (widget.selectedUser != oldWidget.selectedUser) {
      _searchController.text = widget.selectedUser?.displayName ?? '';
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await _userRepository.getAllUsers();
      setState(() {
        _allUsers = users.where((user) {
          // Filter by active users
          if (!user.isActive) return false;

          // Filter by user types if specified
          if (widget.filterByUserTypes != null) {
            return widget.filterByUserTypes!.contains(user.userType);
          }

          return true;
        }).toList();

        _filteredUsers = _allUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user.displayName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.userType.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showDropdown() {
    if (_isDropdownOpen) return;

    setState(() => _isDropdownOpen = true);

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      setState(() => _isDropdownOpen = false);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _filteredUsers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final isSelected = widget.selectedUser?.uid == user.uid;

                        return InkWell(
                          onTap: () => _selectUser(user),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withOpacity(0.1)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _getUserTypeColor(
                                    user.userType,
                                  ),
                                  child: Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppTheme.primary
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '${_getUserTypeLabel(user.userType)} • ${user.email}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectUser(UserModel user) {
    setState(() {
      _searchController.text = user.displayName;
    });
    widget.onUserSelected(user);
    _removeOverlay();
  }

  void _clearSelection() {
    setState(() {
      _searchController.clear();
    });
    widget.onUserSelected(null);
    _removeOverlay();
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.red;
      case UserType.lecturer:
        return Colors.blue;
    }
  }

  String _getUserTypeLabel(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'Admin';
      case UserType.lecturer:
        return 'Lecturer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<UserModel>(
      validator: widget.validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                onTap: _showDropdown,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: field.hasError
                          ? Colors.red
                          : _isDropdownOpen
                          ? AppTheme.primary
                          : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      prefixIcon: const Icon(Icons.person_search),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.selectedUser != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: _clearSelection,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                          Icon(
                            _isDropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 16.0,
                      ),
                    ),
                    readOnly: true,
                    onTap: _showDropdown,
                  ),
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Text(
                  field.errorText!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
