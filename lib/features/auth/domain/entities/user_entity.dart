import 'package:equatable/equatable.dart';

/// Domain entity — no Flutter/Supabase dependency
/// (04_SYSTEM_ARCHITECTURE.md - Domain Layer).
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String language;
  final String theme;
  final bool emailVerified;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.language = 'fa',
    this.theme = 'system',
    this.emailVerified = false,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        language,
        theme,
        emailVerified,
      ];
}
