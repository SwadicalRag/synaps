import 'package:flutter/material.dart';
import 'package:synaps_flutter/synaps_flutter.dart';

part "main.g.dart";

void main() {
  runApp(MyApp());
}

// Define the counter class
@Controller()
class Counter {
  // Create an observable field for our int counter
  @Observable()
  int counter = 0;

  // Just use `counter` as you would normally if it were a field
  void incrementCounter() {
    counter++;
  }

  void decrementCounter() {
    counter--;
  }

  void zeroCounter() {
    counter = 0;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  // Use .ctx() at the end to get an Observable Controller,
  // which internally manages all of Synaps' logic for you.
  final controller = Counter().ctx();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            // Use Rx() to link Synaps to Flutter
            // and update everything inside this lambda
            // whenever any @Observables that were used
            // inside it changes
            Rx(() => Text(
              '${controller.counter}',
              style: Theme.of(context).textTheme.headline4,
            )),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: controller.incrementCounter,
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
          SizedBox(width: 15),
          FloatingActionButton(
            onPressed: controller.zeroCounter,
            tooltip: 'Zero',
            child: Icon(Icons.settings_backup_restore),
          ),
          SizedBox(width: 15),
          FloatingActionButton(
            onPressed: controller.decrementCounter,
            tooltip: 'Decrement',
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
