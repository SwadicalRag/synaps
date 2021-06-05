import "package:meta/meta.dart";
import "package:synaps/synaps.dart";

typedef void SynapsListenerFunction<T>(T? newValue);
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
  static SynapsOracle get NULL => SynapsControllerInterface.NULL_ORACLE;

  /// This value is passed in as `newValue` for `controller.length` 
  /// 
  /// This is because some special controllers like sets/maps can use
  /// Symbols as their keys/values, and can lead to ambiguity when
  /// using the Listener API
  static SynapsOracle get LENGTH => SynapsControllerInterface.LENGTH_ORACLE;

  /// This value is passed in as `newValue` for `controller.keys` 
  /// 
  /// This is because some special controllers like sets/maps can use
  /// Symbols as their keys/values, and can lead to ambiguity when
  /// using the Listener API
  static SynapsOracle get KEYS => SynapsControllerInterface.KEYS_ORACLE;

  /// True if this oracle represents the `null` value
  bool get isNull => identical(this,SynapsControllerInterface.NULL_ORACLE);

  /// True if this oracle represents the `length` field
  bool get isLength => identical(this,SynapsControllerInterface.LENGTH_ORACLE);

  /// True if this oracle represents the `keys` field
  bool get isKeys => identical(this,SynapsControllerInterface.KEYS_ORACLE);
}

class _NULL_ORACLE extends SynapsOracle {}
class _LENGTH_ORACLE extends SynapsOracle {}
class _KEYS_ORACLE extends SynapsOracle {}

abstract class SynapsControllerInterface<T> {
  /// The value contained inside this interface.
  T get boxedValue;

  static final NULL_ORACLE = _NULL_ORACLE();
  static final LENGTH_ORACLE = _LENGTH_ORACLE();
  static final KEYS_ORACLE = _KEYS_ORACLE();

  final Map<dynamic,dynamic> _dirtySymbols = {};
  final Map<dynamic,Set<SynapsListenerFunction>> _symbolListeners = {};
  final Map<dynamic,Set<SynapsRunOnceListenerFunction>> _symbolRunOnceListeners = {};
  
  /// True if this controller is currently inside [synapsEmitListeners] and is
  /// emitting to listeners
  bool _isEmitting = false;

  /// **INTERNAL. DO NOT USE.**
  /// Called by the generated code's getters to inform synaps
  /// that a field has been accessed.
  void synapsMarkVariableRead(dynamic symbol) {
    Synaps.recordVariableRead(symbol, this);
  }

  /// **INTERNAL. DO NOT USE.**
  /// Called by special synaps objects to inform synaps
  /// that the entire controller has been modified.
  void synapsMarkEverythingDirty(dynamic newValue) {
    // Ensure that we are not currently emitting.
    // i.e. this function must NOT be called from inside a listener
    assert(!_isEmitting,"[synaps] An object was modified inside one of its listeners.");

    // DIRTY DIRTY
    final symbols = _symbolListeners.keys.toSet().union(_symbolRunOnceListeners.keys.toSet());

    for (final symbol in symbols) {
      _dirtySymbols[symbol] = newValue;

      Synaps.recordVariableWrite(symbol, this, symbol != symbols.last);
    }
  }

  /// **INTERNAL. DO NOT USE.**
  /// Called by the generated code's setters to inform synaps
  /// that a field has been modified.
  void synapsMarkVariableDirty(dynamic symbol,dynamic newValue, [bool noPlayback = false]) {
    // Ensure that we are not currently emitting.
    // i.e. this function must NOT be called from inside a listener
    assert(!_isEmitting,"[synaps] A field of an object was modified inside one of its listeners.");

    _dirtySymbols[symbol] = newValue;

    Synaps.recordVariableWrite(symbol, this, noPlayback);
  }

  /// Adds a listener to this controller.
  /// To listen to something, two things are needed:
  /// 1. What is going to be listened to?
  /// 2. The actual listener callback.
  /// 
  /// The listener function is given `newValue`, which is the new value
  /// of the field, key or entry that was changed.
  /// 
  /// When a field, key or entry is assigned `null`, the listener function receives
  /// a `NullOracle` as its `newValue` parameter. To check if a field has been nulled,
  /// first cast `newValue` to a SynapsOracle, and then use .isNull
  /// 
  /// ```
  /// synapsAddListener(something,(dynamic newValue) {
  ///   if((newValue is SynapsOracle) && newValue.isNull) {
  ///     // assigned null!
  ///   }
  /// });
  /// ```
  /// 
  /// [synapsAddListener] requires a "symbol" to figure out what to listen to.
  /// A symbol is a way to represent the field, key or entry that is being changed.
  /// 
  /// In a SynapsControllerInterface for a class, this "symbol" will be an actual
  /// [Symbol] of the field itself. That is, given `someClass.someField`,
  /// and the aim is to listen to `someField`, the symbol will be
  ///  `Symbol("someField")`
  /// 
  /// For more complex controllers, [Symbol]s are not used to track the
  /// field, key or entry being changed.
  /// 
  /// In a List, this "symbol" will be the integer index of a field inside
  /// the list.
  /// That is, given `someClass.someList`, and the aim is to listen to
  /// `someList.length` and `someList[3]`, the symbols are `Symbol("length")`
  /// and `(int) 3` respectively
  /// 
  /// In a Set, this "symbol" will be an entry inside the set itself.
  /// That is, given `someClass.someSet`, and the aim is to listen to `someSet.first`
  /// (where this is equal to `"someValue"`), the symbol is `(String) "someValue"`
  /// 
  /// In a Map, this "symbol" will be one of the keys inside the map itself.
  /// That is, given `someClass.someSet`, and the aim is to listen to `someSet[someOtherValue]`
  /// (where `someOtherValue` is of type `SomeOtherClass`), the symbol is 
  /// `(SomeOtherClass) someOtherValue`
  /// 
  /// Special cases include `.length` fields, and `.keys` fields, both of which become
  /// a `LengthOracle` and a `KeyOracle` respectively
  /// 
  /// ```
  /// // Listen to changes to `length` field
  /// synapsAddListener(SynapsOracle.LENGTH,(dynamic newValue) {
  ///   // length changed!
  /// });
  /// ```
  /// 
  void synapsAddListener<T>(dynamic symbol,SynapsListenerFunction<T> listener) {
    if(!_symbolListeners.containsKey(symbol)) {
      _symbolListeners[symbol] = {};
    }

    _symbolListeners[symbol]!.add(listener as void Function(dynamic));
  }

  /// Removes a listener from this controller.
  /// The listener function needs to be exactly the same function
  /// that was originally passed into synapsAddListener
  void synapsRemoveListener<T>(dynamic symbol,SynapsListenerFunction<T> listener) {
    if(!_symbolListeners.containsKey(symbol)) {
      return;
    }

    _symbolListeners[symbol]!.remove(listener);

    if(_symbolListeners[symbol]!.isEmpty) {
      _symbolListeners.remove(symbol);
    }
  }

  /// Adds a runOnce listener to this controller. This listener is guaranteed to run
  /// once per transaction. (i.e. if multiple fields were modified during a transaction,
  /// and the same runOnce listener was added to multiple fields, that listener will only
  /// be called once)
  /// 
  /// See [synapsAddListener]
  void synapsAddRunOnceListener(dynamic symbol,SynapsRunOnceListenerFunction listener) {
    if(!_symbolRunOnceListeners.containsKey(symbol)) {
      _symbolRunOnceListeners[symbol] = {};
    }

    _symbolRunOnceListeners[symbol]!.add(listener);
  }

  /// Adds a runOnce listener to this controller.
  /// 
  /// See [synapsAddListener]
  void synapsRemoveRunOnceListener(dynamic symbol,SynapsRunOnceListenerFunction listener) {
    if(!_symbolRunOnceListeners.containsKey(symbol)) {
      return;
    }

    _symbolRunOnceListeners[symbol]!.remove(listener);

    if(_symbolRunOnceListeners[symbol]!.isEmpty) {
      _symbolRunOnceListeners.remove(symbol);
    }
  }

  /// **INTERNAL. DO NOT USE.**
  /// Calls each listener for every update that has been recorded into this controller
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

        final listeners = _symbolRunOnceListeners[symbol]!;

        for(final listener in listeners) {
          if(!seenRunOnceListeners.contains(listener)) {
            seenRunOnceListeners.add(listener);
            
            listener();
          }
        }
      }

      for(final symbol in _dirtySymbols.keys) {
        if(_symbolListeners[symbol] == null) {continue;}

        final listeners = _symbolListeners[symbol]!;

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
