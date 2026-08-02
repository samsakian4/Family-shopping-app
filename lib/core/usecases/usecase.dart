import 'package:family_shopping_app/core/utils/typedefs.dart';

/// Every use case has a single `call()` method with one params object
/// (04_SYSTEM_ARCHITECTURE.md - Application Layer: Use Cases).
abstract class UseCase<Type, Params> {
  ResultFuture<Type> call(Params params);
}
