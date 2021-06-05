import "package:synaps/synaps.dart";

part "list.g.dart";

@Controller()
class ListTest {
  @Observable()
  List<int?> numberwang = [2,5,3];
}
