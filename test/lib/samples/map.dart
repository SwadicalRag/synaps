import "package:synaps/synaps.dart";

part "map.g.dart";

@Controller()
class MapTest {
  @Observable()
  Map<String,String> ecgWaves = {
    "P": "atrial depolarisation",
    "QRS": "ventricular depolarisation",
    "T": "ventricular repolarisation",
  };

  void explainECG(void Function(String) callback) {
    callback("An ECG has ${ecgWaves.length} waves");

    for(final wave in ecgWaves.keys) {
      callback("The ${wave} wave is correlated with ${ecgWaves[wave]}");
    }

    callback("Now that wasn't so hard, was it?");
  }
}
