import "package:build/build.dart";
import "package:source_gen/source_gen.dart";
import "package:synaps_generator/src/observable_generator.dart";

Builder synapsGeneratorBuilder(BuilderOptions options) {
  return SharedPartBuilder([ObservableGenerator()], "synaps");
}
