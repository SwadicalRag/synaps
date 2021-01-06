// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// ObservableGenerator
// **************************************************************************

class _CounterStateController extends CounterState with ControllerInterface {
  final CounterState _internal;
  @override
  int get counter {
    synapsMarkVariableRead(#counter);
    return _internal.counter;
  }

  @override
  set counter(int value) {
    _internal.counter = value;
    synapsMarkVariableDirty(#counter, value);
  }

  _CounterStateController(this._internal);
}

extension CounterStateControllerExtension on CounterState {
  _CounterStateController asController() {
    if (this is _CounterStateController) return this;
    return _CounterStateController(this);
  }

  _CounterStateController ctx() => asController();
}
