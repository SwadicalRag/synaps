import "dart:collection";

import "package:synaps/synaps.dart";

class SynapsMapKeysIterator<K,V> extends Iterator<K> {
  final SynapsMap<K,V> _synapsMap;
  final Map<K,V> _internalMap;
  
  Iterator<K> _internal;

  SynapsMapKeysIterator(this._synapsMap,this._internalMap) {
    _internal = _internalMap.keys.iterator;
  }
  
  @override
  bool moveNext() {
    final moved = _internal.moveNext();

    if(moved) {
      _synapsMap.synapsMarkVariableRead(_internal.current);
    }

    return moved;
  }

  @override
  K get current {
    _synapsMap.synapsMarkVariableRead(_internal.current);
    return _internal.current;
  }
}

class SynapsMapKeysIterable<K,V> extends Iterable<K> {
  final SynapsMap<K,V> _synapsMap;
  final Map<K,V> _internalMap;
  
  SynapsMapKeysIterable(this._synapsMap,this._internalMap);

  @override
  Iterator<K> get iterator => SynapsMapKeysIterator<K,V>(_synapsMap,_internalMap);
}

class SynapsMap<K,V> extends MapMixin<K,V> with ControllerInterface {
  final Map<K,V> _internal;

  Iterable<K> _keysInternal;
  SynapsMap([this._internal = const {}]) {
    _keysInternal = SynapsMapKeysIterable<K,V>(this,_internal);
  }

  @override
  V operator [](Object index) {
    synapsMarkVariableRead(index);
    return _internal[index];
  }

  @override
  void operator []=(K index,V value) {
    final oldValue = _internal[index];
    _internal[index] = value;

    if(oldValue != value) {
      synapsMarkVariableDirty(index,value,true);
      synapsMarkVariableDirty(ControllerInterface.KEYS_ORACLE,_internal.length,true);
      synapsMarkVariableDirty(ControllerInterface.LENGTH_ORACLE,_internal.length);
    }
  }

  @override
  void clear() {
    synapsMarkEverythingDirty(ControllerInterface.NULL_ORACLE);
    _internal.clear();
  }

  @override
  V remove(Object key) {
    final removed = _internal.remove(key);
    if(removed != null) {
      synapsMarkVariableDirty(key,ControllerInterface.NULL_ORACLE,true);
      synapsMarkVariableDirty(ControllerInterface.KEYS_ORACLE,_internal.length,true);
      synapsMarkVariableDirty(ControllerInterface.LENGTH_ORACLE,_internal.length);
    }
    return removed;
  }

  @override
  int get length {
    synapsMarkVariableRead(ControllerInterface.LENGTH_ORACLE);
    return _internal.length;
  }

  @override
  Iterable<K> get keys {
    synapsMarkVariableRead(ControllerInterface.KEYS_ORACLE);
    return _keysInternal;
  }
}
