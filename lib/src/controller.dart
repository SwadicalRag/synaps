import "package:synaps/synaps.dart";

typedef void SynapsListenerFunction<T>(T newValue);
typedef void SynapsSingleListenerFunction();

class ControllerInterface {
  // Define any methods the controller should implement here

  final Map<dynamic,dynamic> _dirtySymbols = {};
  final Map<dynamic,Set<SynapsListenerFunction>> _symbolListeners = {};
  final Map<dynamic,Set<SynapsSingleListenerFunction>> _symbolSingleListeners = {};
  bool _isEmitting = false;

  void synapsMarkVariableRead(dynamic symbol) {
    SynapsMasterController.recordVariableRead(symbol, this);
  }

  void synapsMarkEverythingDirty(dynamic newValue) {
    if(_isEmitting) {
      // If we reached here, then a variable was modified inside
      // a listener. This is not good. Therefore we'll ignore it.

      // TODO: warn about this when in debug mode

      return;
    }

    // DIRTY DIRTY
    final symbols = _symbolListeners.keys.toSet().union(_symbolSingleListeners.keys.toSet());

    for (final symbol in symbols) {
      _dirtySymbols[symbol] = newValue;

      SynapsMasterController.recordVariableWrite(symbol, this, symbol != symbols.last);
    }
  }

  void synapsMarkVariableDirty(dynamic symbol,dynamic newValue, [bool noPlayback = false]) {
    if(_isEmitting) {
      // If we reached here, then a variable was modified inside
      // a listener. This is not good. Therefore we'll ignore it.

      // TODO: warn about this when in debug mode

      return;
    }

    _dirtySymbols[symbol] = newValue;

    SynapsMasterController.recordVariableWrite(symbol, this, noPlayback);
  }

  void synapsAddListener<T>(dynamic symbol,SynapsListenerFunction<T> listener) {
    if(!_symbolListeners.containsKey(symbol)) {
      _symbolListeners[symbol] = {};
    }

    _symbolListeners[symbol].add(listener);
  }

  void synapsAddSingleListener(dynamic symbol,SynapsSingleListenerFunction listener) {
    if(!_symbolSingleListeners.containsKey(symbol)) {
      _symbolSingleListeners[symbol] = {};
    }

    _symbolSingleListeners[symbol].add(listener);
  }

  void synapsEmitListeners() {
    if(_isEmitting) {
      // If we reached here, then an emit was explicitly called
      // during a listener. This is not good. Therefore we'll ignore it.

      // TODO: warn about this when in debug mode

      return;
    }

    _isEmitting = true;

    try {
      final seenSingleListeners = <SynapsSingleListenerFunction>{};
      for(final symbol in _dirtySymbols.keys) {
        if(_symbolSingleListeners[symbol] == null) {continue;}

        final listeners = _symbolSingleListeners[symbol];

        for(final listener in listeners) {
          if(!seenSingleListeners.contains(listener)) {
            seenSingleListeners.add(listener);
            
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
