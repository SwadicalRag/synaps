import "package:meta/meta.dart";
import 'package:synaps/src/controller.dart';

/// Applying this mixin to your controller class will make the following work:
/// 
/// ```
/// final base = Hello();
/// final ctx1 = base.ctx();
/// final ctx2 = base.ctx();
/// 
/// final imposter = Hello();
/// 
/// base == ctx1; // true
/// base == ctx2; // true
/// ctx1 == ctx2; // true
/// ctx1 == imposter; // false
/// ```
class WeakEqualityController {
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is SynapsControllerInterface) {
      if(identical(other.boxedValue, this)) {
        return true;
      }
    }

    return false;
  }
}
