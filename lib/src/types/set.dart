import "dart:collection";

import "package:synaps/synaps.dart";

class SynapsSetIterator<T> extends Iterator<T> {
  final SynapsSet<T> _synapsSet;
  final Set<T> _internalSet;
  
  Iterator<T> boxedValue;

  SynapsSetIterator(this._synapsSet,this._internalSet) {
    boxedValue = _internalSet.iterator;
  }
  
  @override
  bool moveNext() {
    final moved = boxedValue.moveNext();

    if(moved) {
      _synapsSet.synapsMarkVariableRead(boxedValue.current);
    }

    return moved;
  }

  @override
  T get current {
    _synapsSet.synapsMarkVariableRead(boxedValue.current);
    return boxedValue.current;
  }
}

class SynapsSet<T> extends SetMixin<T> with SynapsControllerInterface<Set<T>> {
  @override
  final Set<T> boxedValue;

  SynapsSet([this.boxedValue = const {}]);

  @override
  bool contains(Object value) {
    synapsMarkVariableRead(value);
    return boxedValue.contains(value);
  }

  @override
  bool add(T value) {
    final changed = boxedValue.add(value);
    if(changed) {
      synapsMarkVariableDirty(value,value,true);
      synapsMarkVariableDirty(SynapsControllerInterface.LENGTH_ORACLE,boxedValue.length);
    }
    return changed;
  }

  @override
  T lookup(Object value) {
    synapsMarkVariableRead(value);
    return boxedValue.lookup(value);
  }

  @override
  bool remove(Object value) {
    final changed = boxedValue.remove(value);
    if(changed) {
      synapsMarkVariableDirty(value,SynapsControllerInterface.NULL_ORACLE,true);
      synapsMarkVariableDirty(SynapsControllerInterface.LENGTH_ORACLE,boxedValue.length);
    }
    return changed;
  }

  @override
  SynapsSet<T> toSet() {
    final dartSet = boxedValue.toSet();
    final proxySet = SynapsSet<T>(dartSet);
    return proxySet;
  }

  @override
  Iterator<T> get iterator => SynapsSetIterator<T>(this,boxedValue);

  @override
  int get length {
    synapsMarkVariableRead(SynapsControllerInterface.LENGTH_ORACLE);
    return boxedValue.length;
  }
}
