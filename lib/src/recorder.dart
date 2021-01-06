import "package:synaps/src/controller.dart";
import "package:meta/meta.dart";

typedef void SynapsTransactionFunction();
typedef void SynapsMonitorFunction();
typedef void SynapsMonitorGranularCallbackFunction(ControllerInterface interface, dynamic symbol,dynamic newValue);
typedef void SynapsMonitorCallbackFunction();

/// what to do when a variable is read from
enum SynapsRecorderMode {
  /// dump all recorded variable reads to void
  VOID,

  /// save all recorded variable reads
  RECORD,
}

class SynapsRecorderState {
  /// Map of Interfaces to a Set of Symbols that were read from
  final Map<ControllerInterface,Set<dynamic>> internalState = {};
  SynapsRecorderMode mode = SynapsRecorderMode.VOID;
}

/// what to do when a variable is written to
enum SynapsPlaybackMode {
  /// don't do anything when the variable is written to
  PAUSED,

  /// start playback as soon as the variable is written to
  LIVE,

  /// currently playing back, so all variable writes will be ignored
  PLAYING,
}

class SynapsPlaybackState {
  /// Map of Interfaces to a Set of Symbols that were written to
  final Map<ControllerInterface,Set<dynamic>> internalState = {};
  SynapsPlaybackMode mode = SynapsPlaybackMode.LIVE;
}

/// The MonitorState is used to manage each listener callback linked to a ControllerInterface
class MonitorState {
  final Map<ControllerInterface,Map<dynamic,Set<SynapsListenerFunction>>> _listeners = {};
  final Map<ControllerInterface,Map<dynamic,Set<SynapsRunOnceListenerFunction>>> _runOnceListeners = {};

  /// Set to true when this MonitorState attaches a listener for the first time,
  /// and does not change afterwards at all.
  bool hasCapturedSymbols = false;

  /// Adds a listener to an interface
  /// 
  /// ```
  /// monitorState.addListener<T>(controller, Symbol("wow"), (T newValue) {
  ///   print("controller.wow was updated to ${newValue}!");
  /// })
  /// ```
  void addListener<T>(ControllerInterface interface,dynamic symbol,SynapsListenerFunction<T> listener) {
    if(!_listeners.containsKey(interface)) {
      _listeners[interface] = {};
    }
    if(!_listeners[interface].containsKey(symbol)) {
      _listeners[interface][symbol] = {};
    }

    _listeners[interface][symbol].add(listener);
    interface.synapsAddListener(symbol, listener);
    hasCapturedSymbols = true;
  }


  /// Removes a listener from an interface
  /// 
  /// ```
  /// final listener = (T newValue) {
  ///   print("controller.wow was updated to ${newValue}!");
  /// };
  /// 
  /// monitorState.addListener<T>(controller, Symbol("wow"), listener);
  /// ...
  /// monitorState.removeListener(controller, Symbol("wow"), listener);
  /// 
  /// ```
  void removeListener<T>(ControllerInterface interface,dynamic symbol,SynapsListenerFunction<T> listener) {
    if(_listeners.containsKey(interface)) {
      if(_listeners[interface].containsKey(symbol)) {
        _listeners[interface][symbol].remove(listener);
      }
    }

    interface.synapsRemoveListener(symbol, listener);
  }


  /// Adds a runOnceListener to an interface
  /// 
  /// Used internally to only call the given listener once despite multiple
  /// changes to a field in a single transaction.
  /// 
  /// ```
  /// final listener = () {
  ///   print("something was updated!");
  /// };
  /// 
  /// monitorState.addRunOnceListener(controller, Symbol("wow"), listener);
  /// monitorState.addRunOnceListener(controller, Symbol("hooh"), listener);
  /// 
  /// SynapsMasterController.transaction(() {
  ///   controller.wow = "something";
  ///   controller.hooh = "something else";
  /// });
  /// 
  /// /// `listener` is only called once!
  /// ```
  void addRunOnceListener(ControllerInterface interface,dynamic symbol,SynapsRunOnceListenerFunction listener) {
    if(!_runOnceListeners.containsKey(interface)) {
      _runOnceListeners[interface] = {};
    }
    if(!_runOnceListeners[interface].containsKey(symbol)) {
      _runOnceListeners[interface][symbol] = {};
    }

    _runOnceListeners[interface][symbol].add(listener);
    interface.synapsAddRunOnceListener(symbol, listener);
    hasCapturedSymbols = true;
  }


  /// Removes a runOnceListener from an interface
  /// 
  /// ```
  /// final listener = () {
  ///   print("controller.wow was updated!");
  /// };
  /// 
  /// monitorState.addRunOnceListener(controller, Symbol("wow"), listener);
  /// ...
  /// monitorState.removeRunOnceListener(controller, Symbol("wow"), listener);
  /// 
  /// ```
  void removeRunOnceListener(ControllerInterface interface,dynamic symbol,SynapsRunOnceListenerFunction listener) {
    if(_runOnceListeners.containsKey(interface)) {
      if(_runOnceListeners[interface].containsKey(symbol)) {
        _runOnceListeners[interface][symbol].remove(listener);
      }
    }

    interface.synapsRemoveRunOnceListener(symbol, listener);
  }

  /// Removes all listeners registered in this MonitorState
  void removeAllListeners() {
    for(final interface in _listeners.keys) {
      final symbolMap = _listeners[interface];
      for(final symbol in symbolMap.keys) {
        final listeners = symbolMap[symbol];

        for(final listener in listeners) {
          interface.synapsRemoveListener(symbol, listener);
        }
      }
    }

    _listeners.clear();
  }

  /// Removes all runOnceListeners registered in this MonitorState
  void removeAllRunOnceListeners() {
    for(final interface in _runOnceListeners.keys) {
      final symbolMap = _runOnceListeners[interface];
      for(final symbol in symbolMap.keys) {
        final listeners = symbolMap[symbol];

        for(final listener in listeners) {
          interface.synapsRemoveRunOnceListener(symbol, listener);
        }
      }
    }

    _runOnceListeners.clear();
  }

  /// Internally removes all kinds of listeners registered with this MonitorState
  void dispose() {
    removeAllListeners();
    removeAllRunOnceListeners();
  }
}

/// The Synaps master controller
/// 
/// It contains some global state to keep track of every single
/// field write/read, and houses the Public API to consume
/// the read/write events.
/// 
class SynapsMasterController {
  static final _masterPlaybackState = SynapsPlaybackState();
  static final _recorderStateStack = <SynapsRecorderState>[];
  static final _playbackStateStack = <SynapsPlaybackState>[];

  /// Returns true if we are currently recording all variable reads
  static bool get isRecording {
    if(_recorderStateStack.isEmpty) {
      return false;
    }

    return _recorderStateStack.last.mode == SynapsRecorderMode.RECORD;
  }

  /// Current recorder state. May be null.
  static SynapsRecorderState get _recorderState {
    return _recorderStateStack.last;
  }

  /// Returns true if we will start playback on the next variable write
  static bool get isLive {
    if(_playbackStateStack.isEmpty) {
      return _masterPlaybackState.mode == SynapsPlaybackMode.LIVE;
    }

    return _playbackStateStack.last.mode == SynapsPlaybackMode.LIVE;
  }

  /// Current playback state. Guaranteed not null.
  static SynapsPlaybackState get _playbackState {
    if(_playbackStateStack.isEmpty) {
      return _masterPlaybackState;
    }

    return _playbackStateStack.last;
  }


  /// **INTERNAL. DO NOT USE.**
  /// should *only* be called by [ControllerInterface]
  /// 
  /// **USE THE PUBLIC API INSTEAD**
  /// See [SynapsMasterController.transaction], [SynapsMasterController.monitor], 
  ///  [SynapsMasterController.monitorGranular], or [SynapsMasterController.ignore]
  /// 
  /// Used by [ControllerInterface] to save variable reads to the current
  /// recorder state
  static void recordVariableRead(dynamic symbol,ControllerInterface interface) {
    if(isRecording) {
      if(!_recorderState.internalState.containsKey(interface)) {
        _recorderState.internalState[interface] = {};
      }

      _recorderState.internalState[interface].add(symbol);
    }
  }


  /// **INTERNAL. DO NOT USE.**
  /// should *only* be called by [ControllerInterface]
  /// 
  /// **USE THE PUBLIC API INSTEAD**
  /// See [SynapsMasterController.transaction], [SynapsMasterController.monitor], 
  ///  [SynapsMasterController.monitorGranular], or [SynapsMasterController.ignore]
  /// 
  /// Used by Public API to start saving variable 
  /// reads to the current recorder state
  static void startRecording([SynapsRecorderMode mode = SynapsRecorderMode.RECORD]) {
    final newState = SynapsRecorderState();
    newState.mode = mode;
    _recorderStateStack.add(newState);
  }


  /// **INTERNAL. DO NOT USE.**
  /// should *only* be called by [ControllerInterface]
  /// 
  /// **USE THE PUBLIC API INSTEAD**
  /// See [SynapsMasterController.transaction], [SynapsMasterController.monitor], 
  ///  [SynapsMasterController.monitorGranular], or [SynapsMasterController.ignore]
  /// 
  /// Used by the Public API to stop saving variable 
  /// reads to the current recorder state
  /// 
  static void stopRecording() {
    if(!isRecording) {
      // TODO: warn here when in debug mode

      return;
    }

    _recorderStateStack.removeLast();
  }


  /// **INTERNAL. DO NOT USE.**
  /// should *only* be called by [ControllerInterface]
  /// 
  /// **USE THE PUBLIC API INSTEAD**
  /// See [SynapsMasterController.transaction], [SynapsMasterController.monitor], 
  ///  [SynapsMasterController.monitorGranular], or [SynapsMasterController.ignore]
  /// 
  /// Used by [ControllerInterface] to save variable writes to the current
  /// playback state
  /// 
  static void recordVariableWrite(dynamic symbol,ControllerInterface interface, [bool noPlayback = false]) {
    if(!_playbackState.internalState.containsKey(interface)) {
      _playbackState.internalState[interface] = {};
    }

    _playbackState.internalState[interface].add(symbol);
    if(isLive && !noPlayback) {
      doPlayback();
    }
  }


  /// **INTERNAL. DO NOT USE.**
  /// should *only* be called by [ControllerInterface]
  /// 
  /// **USE THE PUBLIC API INSTEAD**
  /// See [SynapsMasterController.transaction], [SynapsMasterController.monitor], 
  ///  [SynapsMasterController.monitorGranular], or [SynapsMasterController.ignore]
  /// 
  /// Used by the Public API to start saving variable 
  /// writes to the current recorder state
  /// 
  static void startPlayback([SynapsPlaybackMode mode = SynapsPlaybackMode.LIVE]) {
    final newState = SynapsPlaybackState();
    newState.mode = mode;
    _playbackStateStack.add(newState);
  }


  /// **INTERNAL. DO NOT USE.**
  /// should *only* be called by [ControllerInterface]
  /// 
  /// **USE THE PUBLIC API INSTEAD**
  /// See [SynapsMasterController.transaction], [SynapsMasterController.monitor], 
  ///  [SynapsMasterController.monitorGranular], or [SynapsMasterController.ignore]
  /// 
  /// Used by the Public API to stop saving variable 
  /// writes to the current recorder state
  /// 
  static void stopPlayback() {
    if(_playbackStateStack.isEmpty) {
      // TODO: warn here when in debug mode

      return;
    }

    _playbackStateStack.removeLast();
  }

  /// **INTERNAL. DO NOT USE.**
  /// should *only* be called by [ControllerInterface]
  /// 
  /// **USE THE PUBLIC API INSTEAD**
  /// See [SynapsMasterController.transaction], [SynapsMasterController.monitor], 
  ///  [SynapsMasterController.monitorGranular], or [SynapsMasterController.ignore]
  /// 
  /// Used by the Public API to start the logic to call each listener
  /// inside each [ControllerInterface] 
  /// 
  static void doPlayback() {
    final lastMode = _playbackState.mode;
    _playbackState.mode = SynapsPlaybackMode.PLAYING;

    try {
      for(final interface in _playbackState.internalState.keys) {
        interface.synapsEmitListeners();
      }
    }
    finally {
      _playbackState.mode = lastMode;
      _playbackState.internalState.clear();
    }
  }

  /// Calls the given function, but does not record any variable reads and writes
  /// while that function executes. (Unless a sub-function explicitly
  /// calls [monitor]/[monitorGranular]/[transaction])
  static void ignore(SynapsTransactionFunction fn) {
    startRecording(SynapsRecorderMode.VOID);
    startPlayback(SynapsPlaybackMode.PAUSED);

    try {
      fn();
    }
    finally {
      stopPlayback();
      stopRecording();
    }
  }

  /// Calls the given function `monitor`, but and records any variable reads
  /// while that function executes.
  /// 
  /// ***You should call [MonitorState.dispose] once finished with monitoring***
  /// 
  /// Will call `onUpdate` for every subsequent single variable that is updated.
  /// 
  /// i.e. if three variables are updated in a single playback, then `onUpdate` will
  /// be called three times, once for each variable
  /// 
  static MonitorState monitorGranular({@required SynapsMonitorFunction monitor,@required SynapsMonitorGranularCallbackFunction onUpdate}) {
    final state = MonitorState();

    startRecording(SynapsRecorderMode.RECORD);

    try {
      monitor();

      for(final interface in _recorderState.internalState.keys) {
        final symbols = _recorderState.internalState[interface];

        for(final symbol in symbols) {
          state.addListener(interface, symbol, (newValue) {
            onUpdate(interface, symbol, newValue);
          });
        }
      }
    }
    finally {
      stopRecording();
    }

    return state;
  }


  /// Calls the given function `monitor`, but and records any variable reads
  /// while that function executes.
  /// 
  /// ***You should call [MonitorState.dispose] once finished with monitoring***
  /// 
  /// Will call `onUpdate` when at most once per update
  /// 
  /// i.e. if three variables are updated in a single playback, then `onUpdate` will
  /// be called once
  /// 
  static MonitorState monitor({@required SynapsMonitorFunction monitor,@required SynapsMonitorCallbackFunction onUpdate}) {
    final state = MonitorState();

    startRecording(SynapsRecorderMode.RECORD);

    try {
      monitor();

      for(final interface in _recorderState.internalState.keys) {
        final symbols = _recorderState.internalState[interface];

        for(final symbol in symbols) {
          state.addRunOnceListener(interface, symbol, onUpdate);
        }
      }
    }
    finally {
      stopRecording();
    }

    return state;
  }

  /// Calls the given function, and records all variable *writes*, and combines
  /// them into one playback event.
  /// 
  /// If an error is thrown inside the transaction, the playback event is abandoned, and
  /// no callbacks are triggered.
  /// 
  static void transaction(SynapsTransactionFunction fn) {
    startPlayback(SynapsPlaybackMode.PAUSED);

    try {
      fn();
      doPlayback();
    }
    finally {
      stopPlayback();
    }
  }
}
