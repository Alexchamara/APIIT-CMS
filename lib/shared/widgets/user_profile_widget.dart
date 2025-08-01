import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:flutter/material.dart';

class UserProfileWidget extends StatelessWidget {
  final UserModel user;
  final double size;
  final bool showDetails;

  const UserProfileWidget({
    super.key,
    required this.user,
    this.size = 50,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: showDetails
          ? Row(
              children: [
                _buildProfileImage(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.displayName,
                        style: AppTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: AppTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: user.userType == UserType.admin
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.userType.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: user.userType == UserType.admin
                                ? AppTheme.primary
                                : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildProfileImage(),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.lightGrey,
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: user.profilePictureUrl != null
            ? Image.network(
                user.profilePictureUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.1),
      child: Icon(Icons.person, size: size * 0.6, color: AppTheme.primary),
    );
  }
}
