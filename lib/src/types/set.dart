import "dart:collection";

import "package:synaps/synaps.dart";

class SynapsSetIterator<T> extends Iterator<T> {
  final SynapsSet<T> _synapsSet;
  final Set<T> _internalSet;
  
  Iterator<T> _internal;

  SynapsSetIterator(this._synapsSet,this._internalSet) {
    _internal = _internalSet.iterator;
  }
  
  @override
  bool moveNext() {
    final moved = _internal.moveNext();

    if(moved) {
      _synapsSet.synapsMarkVariableRead(_internal.current);
    }

    return moved;
  }

  @override
  T get current {
    _synapsSet.synapsMarkVariableRead(_internal.current);
    return _internal.current;
  }
}

class SynapsSet<T> extends SetMixin<T> with SynapsControllerInterface {
  final Set<T> _internal;

  SynapsSet([this._internal = const {}]);

  @override
  bool contains(Object value) {
    synapsMarkVariableRead(value);
    return _internal.contains(value);
  }

  @override
  bool add(T value) {
    final changed = _internal.add(value);
    if(changed) {
      synapsMarkVariableDirty(value,value,true);
      synapsMarkVariableDirty(SynapsControllerInterface.LENGTH_ORACLE,_internal.length);
    }
    return changed;
  }

  @override
  T lookup(Object value) {
    synapsMarkVariableRead(value);
    return _internal.lookup(value);
  }

  @override
  bool remove(Object value) {
    final changed = _internal.remove(value);
    if(changed) {
      synapsMarkVariableDirty(value,SynapsControllerInterface.NULL_ORACLE,true);
      synapsMarkVariableDirty(SynapsControllerInterface.LENGTH_ORACLE,_internal.length);
    }
    return changed;
  }

  @override
  SynapsSet<T> toSet() {
    final dartSet = _internal.toSet();
    final proxySet = SynapsSet<T>(dartSet);
    return proxySet;
  }

  @override
  Iterator<T> get iterator => SynapsSetIterator<T>(this,_internal);

  @override
  int get length {
    synapsMarkVariableRead(SynapsControllerInterface.LENGTH_ORACLE);
    return _internal.length;
  }
}
