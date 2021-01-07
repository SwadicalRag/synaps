import "package:synaps/src/overseer.dart";

T Tx<T>(T Function() fn) {
  return Synaps.transaction(fn);
}

T Ix<T>(T Function() fn) {
  return Synaps.ignore(fn);
}

SynapsMonitorState Mx(SynapsMonitorFunction capture,SynapsMonitorCallbackFunction onUpdate) {
  return Synaps.monitor(capture: capture, onUpdate: onUpdate);
}
