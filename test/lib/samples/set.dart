import "package:synaps/synaps.dart";

part "set.g.dart";

@Controller()
class SetTest {
  @Observable()
  Set<String> pizzaToppings = {};

  bool isDisgusting() {
    return pizzaToppings.contains("pineapples");
  }
}
