import "package:synaps/synaps.dart";

typedef void SynapsListenerFunction<T>(T newValue);
typedef void SynapsRunOnceListenerFunction();

class ControllerInterface {
  // Define any methods the controller should implement here

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
