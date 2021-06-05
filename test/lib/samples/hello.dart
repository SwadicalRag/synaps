import "package:synaps/synaps.dart";

part "hello.g.dart";

@Controller()
class Hello with WeakEqualityController {
  @Observable()
  String? world;
  
  @Observable()
  String? universe;

  String imNormal = "i can't be observed";
}
