// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// ObservableGenerator
// **************************************************************************

class $CounterController
    with SynapsControllerInterface<Counter>
    implements Counter {
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
    counter++;
  }

  @override
  void decrementCounter() {
    counter--;
  }

  @override
  void zeroCounter() {
    counter = 0;
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
