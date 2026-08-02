import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/settings/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class UploadAvatarParams extends Equatable {
  final Uint8List bytes;
  final String fileExtension;

  const UploadAvatarParams({required this.bytes, required this.fileExtension});

  @override
  List<Object?> get props => [bytes, fileExtension];
}

class UploadAvatarUseCase implements UseCase<String, UploadAvatarParams> {
  final ProfileRepository _repository;

  UploadAvatarUseCase(this._repository);

  /// Max size 5MB (15_STORAGE.md - File Size Limits: Profile image).
  static const int maxBytes = 5 * 1024 * 1024;
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  @override
  ResultFuture<String> call(UploadAvatarParams params) async {
    if (params.bytes.length > maxBytes) {
      return const Left(ValidationFailure('حجم تصویر نباید بیشتر از ۵ مگابایت باشد'));
    }
    if (!allowedExtensions.contains(params.fileExtension.toLowerCase())) {
      return const Left(ValidationFailure('فرمت تصویر باید JPG، PNG یا WEBP باشد'));
    }
    return _repository.uploadAvatar(params.bytes, fileExtension: params.fileExtension);
  }
}
