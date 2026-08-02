import 'package:dartz/dartz.dart';
import 'package:family_shopping_app/core/errors/failures.dart';

/// Standard return type for repository methods and use cases.
/// Left = Failure, Right = success value.
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;

/// A no-parameters marker for use cases (Clean Architecture convention).
class NoParams {
  const NoParams();
}
