import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/features/settings/domain/repositories/profile_repository.dart';
import 'package:family_shopping_app/features/settings/domain/usecases/upload_avatar_usecase.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;
  late UploadAvatarUseCase useCase;

  setUp(() {
    repository = MockProfileRepository();
    useCase = UploadAvatarUseCase(repository);
  });

  test('rejects a file larger than 5MB (15_STORAGE.md limit)', () async {
    final oversized = Uint8List(UploadAvatarUseCase.maxBytes + 1);

    final result =
        await useCase(UploadAvatarParams(bytes: oversized, fileExtension: 'jpg'));

    expect(result, isA<Left<Failure, String>>());
    verifyNever(() => repository.uploadAvatar(any(), fileExtension: any(named: 'fileExtension')));
  });

  test('rejects an unsupported file extension', () async {
    final small = Uint8List(10);

    final result = await useCase(UploadAvatarParams(bytes: small, fileExtension: 'gif'));

    expect(result, isA<Left<Failure, String>>());
  });

  test('accepts a valid jpg within the size limit and delegates to the repository', () async {
    final small = Uint8List(10);
    when(() => repository.uploadAvatar(any(), fileExtension: any(named: 'fileExtension')))
        .thenAnswer((_) async => const Right('https://example.com/avatar.jpg'));

    final result = await useCase(UploadAvatarParams(bytes: small, fileExtension: 'JPG'));

    expect(result, const Right<Failure, String>('https://example.com/avatar.jpg'));
    verify(() => repository.uploadAvatar(small, fileExtension: 'JPG')).called(1);
  });
}
