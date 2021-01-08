// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_controller.dart';

// **************************************************************************
// ObservableGenerator
// **************************************************************************

class $CounterController extends Counter
    with SynapsControllerInterface<Counter> {
  @override
  final Counter boxedValue;
  @override
  int get clk {
    synapsMarkVariableRead(#clk);
    return boxedValue.clk;
  }

  @override
  set clk(int value) {
    boxedValue.clk = value;
    synapsMarkVariableDirty(#clk, value);
  }

  $CounterController(this.boxedValue);
}

extension CounterControllerExtension on Counter {
  $CounterController asController() {
    if (this is $CounterController) return this;
    return $CounterController(this);
  }

  $CounterController ctx() => asController();
  Counter get boxedValue => this;
}
