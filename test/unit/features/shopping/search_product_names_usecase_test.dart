import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_item_repository.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/search_product_names_usecase.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late SearchProductNamesUseCase useCase;

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = SearchProductNamesUseCase(repository);
  });

  test('delegates the query to the repository and returns its result', () async {
    when(() => repository.searchProductNames('شی'))
        .thenAnswer((_) async => ['شیر کاله', 'شیر پگاه']);

    final result = await useCase('شی');

    expect(result, ['شیر کاله', 'شیر پگاه']);
    verify(() => repository.searchProductNames('شی')).called(1);
  });

  test('returns an empty list for an empty query without special-casing in the use case',
      () async {
    when(() => repository.searchProductNames('')).thenAnswer((_) async => []);

    final result = await useCase('');

    expect(result, isEmpty);
  });
}
