
import "package:synaps/synaps.dart";

part "example_controller.g.dart";

@Controller()
class Counter {
  @Observable()
  int clk = 0;
}
