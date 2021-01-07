// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// ObservableGenerator
// **************************************************************************

class _CounterStateController extends Counter
    with SynapsControllerInterface {
  final Counter _internal;
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

  @override
  void incrementCounter() {
    return super.incrementCounter();
  }

  @override
  void decrementCounter() {
    return super.decrementCounter();
  }

  @override
  void zeroCounter() {
    return super.zeroCounter();
  }

  _CounterStateController(this._internal);
}

extension CounterStateControllerExtension on Counter {
  _CounterStateController asController() {
    if (this is _CounterStateController) return this;
    return _CounterStateController(this);
  }

  _CounterStateController ctx() => asController();
}
