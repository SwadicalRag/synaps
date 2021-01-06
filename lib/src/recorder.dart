import 'package:synaps/src/controller.dart';

typedef void SynapsTransactionFunction();
typedef void SynapsMonitorFunction();
typedef void SynapsMonitorGranularCallbackFunction(dynamic symbol,dynamic newValue);
typedef void SynapsMonitorCallbackFunction();

/// what to do when a variable is read from
enum SynapsRecorderMode {
  /// dump all recorded variable reads to void
  VOID,

  /// save all recorded variable reads
  RECORD,
}

class SynapsRecorderState {
  final internalState = <dynamic,ControllerInterface>{};
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
  final internalState = <dynamic,ControllerInterface>{};
  SynapsPlaybackMode mode = SynapsPlaybackMode.LIVE;
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
      _recorderState.internalState[symbol] = interface;
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
    _playbackState.internalState[symbol] = interface;
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
      for(final interface in _playbackState.internalState.values.toSet()) {
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
  /// Will call `onUpdate` for every subsequent single variable that is updated.
  /// 
  /// i.e. if three variables are updated in a single playback, then `onUpdate` will
  /// be called three times, once for each variable
  /// 
  static void monitorGranular({SynapsMonitorFunction monitor,SynapsMonitorGranularCallbackFunction onUpdate}) {
    startRecording(SynapsRecorderMode.RECORD);

    try {
      monitor();

      for(final symbol in _recorderState.internalState.keys) {
        final interface = _recorderState.internalState[symbol];

        interface.synapsAddListener(symbol, (newValue) {
          onUpdate(symbol,newValue);
        });
      }
    }
    finally {
      stopRecording();
    }
  }


  /// Calls the given function `monitor`, but and records any variable reads
  /// while that function executes.
  /// 
  /// Will call `onUpdate` when at most once per update
  /// 
  /// i.e. if three variables are updated in a single playback, then `onUpdate` will
  /// be called once
  /// 
  static void monitor({SynapsMonitorFunction monitor,SynapsMonitorCallbackFunction onUpdate}) {
    startRecording(SynapsRecorderMode.RECORD);

    try {
      monitor();

      for(final symbol in _recorderState.internalState.keys) {
        final interface = _recorderState.internalState[symbol];

        interface.synapsAddSingleListener(symbol, onUpdate);
      }
    }
    finally {
      stopRecording();
    }
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
