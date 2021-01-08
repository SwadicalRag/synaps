import "package:synaps/synaps.dart";
import "package:synaps_test/samples/hello.dart";

part "reference.g.dart";

@Controller()
class ReferenceTest {
  @Observable()
  Hello world;
  
  @Observable()
  String somethingElse;

  @Observable()
  Set<Hello> greetingz;
}
