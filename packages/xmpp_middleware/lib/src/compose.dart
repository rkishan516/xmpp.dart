import 'context.dart';

/// Middleware function signature.
typedef Middleware<T extends Context> = Future<dynamic> Function(T ctx, Future<dynamic> Function() next);

/// Compose multiple middleware functions into a single middleware.
///
/// Each middleware can call `next()` to pass control to the next
/// middleware in the chain.
Middleware<T> compose<T extends Context>(List<Middleware<T>> middleware) {
  return (T ctx, Future<dynamic> Function() next) async {
    var index = -1;

    Future<dynamic> dispatch(int i) async {
      if (i <= index) {
        throw StateError('next() called multiple times');
      }
      index = i;

      Middleware<T>? fn;
      if (i < middleware.length) {
        fn = middleware[i];
      } else if (i == middleware.length) {
        return next();
      }

      if (fn == null) return null;

      return fn(ctx, () => dispatch(i + 1));
    }

    return dispatch(0);
  };
}
