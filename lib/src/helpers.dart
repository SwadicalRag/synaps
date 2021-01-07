import "package:synaps/src/overseer.dart";

T Tx<T>(T Function() fn) {
  return Synaps.transaction(fn);
}

T Ix<T>(T Function() fn) {
  return Synaps.ignore(fn);
}

SynapsMonitorState Mx(SynapsMonitorFunction monitor,SynapsMonitorCallbackFunction onUpdate) {
  return Synaps.monitor(monitor: monitor, onUpdate: onUpdate);
}
