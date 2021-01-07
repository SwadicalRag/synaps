import "package:synaps/src/recorder.dart";

T Tx<T>(T Function() fn) {
  return SynapsMasterController.transaction(fn);
}

T Ix<T>(T Function() fn) {
  return SynapsMasterController.ignore(fn);
}
