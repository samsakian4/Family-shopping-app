import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
///
/// The Domain/Application layers never throw raw exceptions to the UI;
/// repositories catch exceptions and return a [Failure] via Either
/// (see 04_SYSTEM_ARCHITECTURE.md - Domain Layer must not depend on Flutter).
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'خطا در برقراری ارتباط با سرور']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'اتصال اینترنت برقرار نیست']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'اطلاعات ورود صحیح نیست']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'خطا در دیتابیس محلی']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'شما دسترسی لازم برای این عملیات را ندارید']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'خطای غیرمنتظره‌ای رخ داد']);
}
