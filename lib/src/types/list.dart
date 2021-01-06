import "dart:collection";

import "package:synaps/synaps.dart";

class SynapsList<T> extends ListMixin<T> with ControllerInterface {
  final List<T> _internal;

  SynapsList([this._internal = const []]);

  @override
  T operator [](int index) {
    synapsMarkVariableRead(index);
    return _internal[index];
  }

  @override
  void operator []=(int index,T value) {
    _internal[index] = value;
    synapsMarkVariableDirty(index,value);
  }

  @override
  int get length {
    synapsMarkVariableRead(ControllerInterface.LENGTH_ORACLE);
    return _internal.length;
  }

  @override
  set length(int value) {
    if(value != _internal.length) {
      _internal.length = value;
      synapsMarkVariableDirty(ControllerInterface.LENGTH_ORACLE,value);
    }
  }
}
