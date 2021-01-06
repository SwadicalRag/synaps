import "package:synaps/synaps.dart";

typedef void SynapsListenerFunction<T>(T newValue);
typedef void SynapsRunOnceListenerFunction();

/// An interface to the "Oracle", which is a unique class representing
/// the kind of field that is being changed in a special controller
/// (like a list, set or map)
/// 
/// This is needed because Set/Map can have Symbols as their keys/values,
/// and will lead to ambiguity when using the listener API.
/// Additionally, null values, when assigned to maps (which are 
/// used extensively in synaps), will not iterate correctly.
class SynapsOracle {
  /// This value is passed in as `newValue` whenever `newValue == null`. 
  /// 
  /// This is because null values, when assigned to
  /// maps (which are used extensively in synaps), will not iterate correctly.
  static SynapsOracle get NULL => ControllerInterface.NULL_ORACLE;

  /// This value is passed in as `newValue` for `controller.length` 
  /// 
  /// This is because some special controllers like sets/maps can use
  /// Symbols as their keys/values, and can lead to ambiguity when
  /// using the Listener API
  static SynapsOracle get LENGTH => ControllerInterface.LENGTH_ORACLE;

  /// This value is passed in as `newValue` for `controller.keys` 
  /// 
  /// This is because some special controllers like sets/maps can use
  /// Symbols as their keys/values, and can lead to ambiguity when
  /// using the Listener API
  static SynapsOracle get KEYS => ControllerInterface.KEYS_ORACLE;

  /// True if this oracle represents the `null` value
  bool get isNull => identical(this,ControllerInterface.NULL_ORACLE);

  /// True if this oracle represents the `length` field
  bool get isLength => identical(this,ControllerInterface.LENGTH_ORACLE);

  /// True if this oracle represents the `keys` field
  bool get isKeys => identical(this,ControllerInterface.KEYS_ORACLE);
}

class _NULL_ORACLE extends SynapsOracle {}
class _LENGTH_ORACLE extends SynapsOracle {}
class _KEYS_ORACLE extends SynapsOracle {}

class ControllerInterface {
  static final NULL_ORACLE = _NULL_ORACLE();
  static final LENGTH_ORACLE = _LENGTH_ORACLE();
  static final KEYS_ORACLE = _KEYS_ORACLE();

  final Map<dynamic,dynamic> _dirtySymbols = {};
  final Map<dynamic,Set<SynapsListenerFunction>> _symbolListeners = {};
  final Map<dynamic,Set<SynapsRunOnceListenerFunction>> _symbolRunOnceListeners = {};
  bool _isEmitting = false;

  void synapsMarkVariableRead(dynamic symbol) {
    SynapsMasterController.recordVariableRead(symbol, this);
  }

  void synapsMarkEverythingDirty(dynamic newValue) {
    // Ensure that we are not currently emitting.
    // i.e. this function must NOT be called from inside a listener
    assert(!_isEmitting,"[synaps] An object was modified inside one of its listeners.");

    // DIRTY DIRTY
    final symbols = _symbolListeners.keys.toSet().union(_symbolRunOnceListeners.keys.toSet());

    for (final symbol in symbols) {
      _dirtySymbols[symbol] = newValue;

      SynapsMasterController.recordVariableWrite(symbol, this, symbol != symbols.last);
    }
  }

  void synapsMarkVariableDirty(dynamic symbol,dynamic newValue, [bool noPlayback = false]) {
    // Ensure that we are not currently emitting.
    // i.e. this function must NOT be called from inside a listener
    assert(!_isEmitting,"[synaps] A field of an object was modified inside one of its listeners.");

    _dirtySymbols[symbol] = newValue;

    SynapsMasterController.recordVariableWrite(symbol, this, noPlayback);
  }

  void synapsAddListener<T>(dynamic symbol,SynapsListenerFunction<T> listener) {
    if(!_symbolListeners.containsKey(symbol)) {
      _symbolListeners[symbol] = {};
    }

    _symbolListeners[symbol].add(listener);
  }

  void synapsRemoveListener<T>(dynamic symbol,SynapsListenerFunction<T> listener) {
    if(!_symbolListeners.containsKey(symbol)) {
      return;
    }

    _symbolListeners[symbol].remove(listener);

    if(_symbolListeners[symbol].isEmpty) {
      _symbolListeners.remove(symbol);
    }
  }

  void synapsAddRunOnceListener(dynamic symbol,SynapsRunOnceListenerFunction listener) {
    if(!_symbolRunOnceListeners.containsKey(symbol)) {
      _symbolRunOnceListeners[symbol] = {};
    }

    _symbolRunOnceListeners[symbol].add(listener);
  }

  void synapsRemoveRunOnceListener(dynamic symbol,SynapsRunOnceListenerFunction listener) {
    if(!_symbolRunOnceListeners.containsKey(symbol)) {
      return;
    }

    _symbolRunOnceListeners[symbol].remove(listener);

    if(_symbolRunOnceListeners[symbol].isEmpty) {
      _symbolRunOnceListeners.remove(symbol);
    }
  }

  void synapsEmitListeners() {
    // Ensure that we are not currently emitting.
    // i.e. you shouldn't re-emit while you are already emitting
    // There should already be logic in place to prevent this.
    assert(!_isEmitting,"[synaps] An emit request while trying to fulfil an earlier emit request.");

    _isEmitting = true;

    try {
      final seenRunOnceListeners = <SynapsRunOnceListenerFunction>{};
      for(final symbol in _dirtySymbols.keys) {
        if(_symbolRunOnceListeners[symbol] == null) {continue;}

        final listeners = _symbolRunOnceListeners[symbol];

        for(final listener in listeners) {
          if(!seenRunOnceListeners.contains(listener)) {
            seenRunOnceListeners.add(listener);
            
            listener();
          }
        }
      }

      for(final symbol in _dirtySymbols.keys) {
        if(_symbolListeners[symbol] == null) {continue;}

        final listeners = _symbolListeners[symbol];

        final newValue = _dirtySymbols[symbol];
        for(final listener in listeners) {
          listener(newValue);
        }
      }
    }
    finally {
      _isEmitting = false;
      _dirtySymbols.clear();
    }
  }
}
