// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// ObservableGenerator
// **************************************************************************

class $Counter extends Counter with SynapsControllerInterface<Counter> {
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

  $Counter(this.boxedValue) : super();
}

extension CounterExtension on Counter {
  $Counter asController() {
    if (this is $Counter) return this as $Counter;
    return $Counter(this);
  }

  $Counter ctx() => asController();
  Counter get boxedValue => this;
}
