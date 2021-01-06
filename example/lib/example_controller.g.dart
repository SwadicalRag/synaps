// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_controller.dart';

// **************************************************************************
// ObservableGenerator
// **************************************************************************

class _CounterController extends Counter with ControllerInterface {
  final Counter _internal;
  @override
  int get clk {
    synapsMarkVariableRead(#clk);
    return _internal.clk;
  }

  @override
  set clk(int value) {
    _internal.clk = value;
    synapsMarkVariableDirty(#clk, value);
  }

  _CounterController(this._internal);
}

extension CounterControllerExtension on Counter {
  _CounterController asController() {
    if (this is _CounterController) return this;
    return _CounterController(this);
  }

  _CounterController ctx() => asController();
}
