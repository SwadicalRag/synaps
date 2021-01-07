import "package:synaps/synaps.dart";

import "example_controller.dart";

void someOtherFunc(Counter counter) {
  counter.clk++;
}

void main() {
  // Basic program that prints the value of a changing int

  final counter = Counter().ctx();

  Synaps.monitor(
    monitor: () {
      print("Initial value of counter is ${counter.clk}");
    },
    onUpdate: () {
      print("Something inside was updated");
      print("New value of counter is: ${counter.clk}");
    },
  );

  counter.clk++;

  // just to demonstrate for realsies that this works from anywhere
  someOtherFunc(counter);
}
