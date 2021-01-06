import "dart:collection";

import "package:synaps/synaps.dart";

class SynapsList<T> extends ListMixin<T> with ControllerInterface {
  final List<T> _internal;

  SynapsList([this._internal = const []]);

  Symbol _getSymbolForIndex(int index) {
    return Symbol("list_${index}");
  }

  @override
  T operator [](int index) {
    synapsMarkVariableRead(_getSymbolForIndex(index));
    return _internal[index];
  }

  @override
  void operator []=(int index,T value) {
    _internal[index] = value;
    synapsMarkVariableDirty(_getSymbolForIndex(index),value);
  }

  @override
  int get length {
    synapsMarkVariableRead(#length);
    return _internal.length;
  }

  @override
  set length(int value) {
    if(value != _internal.length) {
      _internal.length = value;
      synapsMarkVariableDirty(#length,value);
    }
  }
}
