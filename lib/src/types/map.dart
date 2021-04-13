import "dart:collection";

import "package:synaps/synaps.dart";

class SynapsMapKeysIterator<K,V> extends Iterator<K> {
  final SynapsMap<K,V> _synapsMap;
  final Map<K,V> _internalMap;
  
  Iterator<K> boxedValue;

  SynapsMapKeysIterator(this._synapsMap,this._internalMap) {
    boxedValue = _internalMap.keys.iterator;
  }
  
  @override
  bool moveNext() {
    final moved = boxedValue.moveNext();

    if(moved) {
      _synapsMap.synapsMarkVariableRead(boxedValue.current);
    }

    return moved;
  }

  @override
  K get current {
    _synapsMap.synapsMarkVariableRead(boxedValue.current);
    return boxedValue.current;
  }
}

class SynapsMapKeysIterable<K,V> extends Iterable<K> {
  final SynapsMap<K,V> _synapsMap;
  final Map<K,V> _internalMap;
  
  SynapsMapKeysIterable(this._synapsMap,this._internalMap);

  @override
  Iterator<K> get iterator => SynapsMapKeysIterator<K,V>(_synapsMap,_internalMap);
}

class SynapsMap<K,V> extends MapMixin<K,V> with SynapsControllerInterface<Map<K,V>> {
  Iterable<K> _keysInternal;

  @override
  final Map<K,V> boxedValue;

  SynapsMap([this.boxedValue = const {}]) {
    _keysInternal = SynapsMapKeysIterable<K,V>(this,boxedValue);
  }

  @override
  V operator [](Object index) {
    synapsMarkVariableRead(index);
    return boxedValue[index];
  }

  @override
  void operator []=(K index,V value) {
    final oldValue = boxedValue[index];
    boxedValue[index] = value;

    if(oldValue != value) {
      synapsMarkVariableDirty(index,value,true);
      synapsMarkVariableDirty(SynapsControllerInterface.KEYS_ORACLE,boxedValue.length,true);
      synapsMarkVariableDirty(SynapsControllerInterface.LENGTH_ORACLE,boxedValue.length);
    }
  }

  @override
  void clear() {
    synapsMarkEverythingDirty(SynapsControllerInterface.NULL_ORACLE);
    boxedValue.clear();
  }

  @override
  V remove(Object key) {
    final removed = boxedValue.remove(key);
    if(removed != null) {
      synapsMarkVariableDirty(key,SynapsControllerInterface.NULL_ORACLE,true);
      synapsMarkVariableDirty(SynapsControllerInterface.KEYS_ORACLE,boxedValue.length,true);
      synapsMarkVariableDirty(SynapsControllerInterface.LENGTH_ORACLE,boxedValue.length);
    }
    return removed;
  }

  @override
  int get length {
    synapsMarkVariableRead(SynapsControllerInterface.LENGTH_ORACLE);
    return boxedValue.length;
  }

  @override
  Iterable<K> get keys {
    synapsMarkVariableRead(SynapsControllerInterface.KEYS_ORACLE);
    return _keysInternal;
  }
}

extension SynapsMapExtension<K,V> on Map<K,V> {
  SynapsMap<K,V> asController() {
    if (this is SynapsMap<K,V>) return this;
    return SynapsMap<K,V>(this);
  }

  SynapsMap<K,V> ctx() => asController();
}
