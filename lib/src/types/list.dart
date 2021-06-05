import "dart:collection";

import "package:synaps/synaps.dart";

class SynapsList<T> extends ListMixin<T?> with SynapsControllerInterface {
  @override
  final List<T?> boxedValue;

  SynapsList([this.boxedValue = const []]);

  @override
  T? operator [](int index) {
    synapsMarkVariableRead(index);
    return boxedValue[index];
  }

  @override
  void operator []=(int index,T? value) {
    boxedValue[index] = value;
    synapsMarkVariableDirty(index,value);
  }

  @override
  int get length {
    synapsMarkVariableRead(SynapsControllerInterface.LENGTH_ORACLE);
    return boxedValue.length;
  }

  @override
  set length(int value) {
    if(value != boxedValue.length) {
      boxedValue.length = value;
      synapsMarkVariableDirty(SynapsControllerInterface.LENGTH_ORACLE,value);
    }
  }
}

extension SynapsListExtension<T> on List<T> {
  SynapsList<T> asController() {
    if (this is SynapsList<T>) return this as SynapsList<T>;
    return SynapsList<T>(this);
  }

  SynapsList<T> ctx() => asController();
}
