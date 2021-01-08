// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// ObservableGenerator
// **************************************************************************

class $CounterController extends Counter
    with SynapsControllerInterface<Counter> {
  @override
  final Counter boxedValue;
  @override
  int get counter {
    synapsMarkVariableRead(#counter);
    return boxedValue.counter;
  }

  @override
  set counter(int value) {
    boxedValue.counter = value;
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
