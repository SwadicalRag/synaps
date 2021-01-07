# 💥 synaps 💊

![](https://forthebadge.com/images/badges/uses-brains.svg)
![](https://forthebadge.com/images/badges/powered-by-black-magic.svg)
![](https://forthebadge.com/images/badges/built-with-swag.svg)

[![Build Status](https://travis-ci.com/SwadicalRag/synaps.svg?token=PTT4FvfoVgjzy67HoFYD&branch=master)](https://travis-ci.com/SwadicalRag/synaps)

synaps provides tools to create observable class fields using decorators.

This library was built to work as the backend for a state management library for Flutter.

On its own, synaps does not depend on Flutter and is completely separate from any framework. Its only major dependencies are `build_runner` and `source_gen`

If you want to use this as a state management solution for UIs, perhaps you should look at `synaps_flutter`. It should have
the methods you need, but neatly packed into widgets and helper functions.

## Why?

### Preamble

I like to think that UI is completely separate from application logic (or business logic).
As an example, when a user clicks a button that increments a number, the code to "add one" to 
that number should not reside inside UI code. This code should be separated into its own file, 
as application logic. Obviously in the real world, abstracting something as trivial as addition 
does not make much sense, but if we consider scenarios like "a button that creates a new object",
where this object is depended upon by other sections of the UI, things start to get complicated.

There are countless solutions to this problem: BLoC, Redux, Providers, etc.
Over the course of the last decade, I have personally tried most of the above solutions, and
found it difficult to justify the volume of boilerplate code I was forced to write when
*properly* using these libraries. If I want to increment a number in the application state,
why on earth do I need a **Store**, which contains the number's **State**, which is sent to the UI,
where the UI sends an Increment**Action** to a **Reducer** which can finally update the **Store**.
Wasn't that exhausting to read?

As an independent developer who has other commitments, a demanding full time degree, and who values
self care, I cannot justify spending so much more time writing code that I *know* has the potential
to be written in an intuitive, relatively concise way.

### From first principles

Please humor me for three minutes.
Let's assume that UI code is completely separate from application code, and ask some questions.

> **Q: What do you call UI that has no application logic?**
>
> **A:** A printed piece of paper. On its own, paper can't change its contents.

> **Q: What does UI need to not be a "piece of paper"?**
> 
> **A:** Data. It needs to represent data, and it needs to be able to accept human input to change data.

> **Q: *Where* does UI code get the data it displays?**
>
> **A:** From application logic

> **Q: *When* does UI code get the data it needs to display?**
>
> **A:** When application data changes

> **Q: *Where* does application logic get the input it needs to function?**
>
> **A:** From the UI code.

> **Q: *When* does application logic get the input it needs to function?**
>
> **A:** When a human interaction occurs with the UI.

> **Q: If the UI and Application logic is completely separate, what's missing?**
>
> **A:** A "glue" code that sends changes in application data to the UI, and also sends/converts
> human interactions into application data.

> **Q: Doesn't this "glue" stuff sound just like BLoC, Redux, etc.?**
>
> **A:** Exactly. But surely we can make some magical "glue" that is intuitive and easy to use?

> **Q: What makes "glue" intuitive?**
>
> **A:** You shouldn't have to learn a new paradigm to use it, and you shouldn't have to write the same
> code in multiple places. An intuitive "glue" should feel like it isn't even there.

> **Q: How can we link UI and Application logic with "[glue] that isn't even there"?**
> 
> **A:** We can re-use already written code as glue.

> **Q: what?**
> 
> **???:** Let me ask you this: what does a "glue" need anyway?
> 
> **A:** A glue needs to know when UI or application data changes, and it needs to know which parts of
> application logic or UI logic depends upon that bit of data, so that it can update the UI or application
> logic.

> **Q: okay but isn't that what we are specifying with Reducers or State or Actions or whatever**
>
> **A:** Exactly. But why re-write what you have already written?

> **Q: Already written? When? Where? By whom?**
> 
> **A:** By you. When you write UI code, all of the variables you reference ***are*** **in** the code you write.
> When you write application logic, you have *already* specified what the UI can listen to in the form of the
> state that the application *already* uses.

> **Q: Yes, but you can't just magically turn already written code into glue.**
> 
> **A:** But what if you ***can***?

![mspaint diagram of everything you just read](img/mspaintdiagram.png)

(sorry I know it's mspaint)

### Enter synaps

Synaps is designed to enable "glue" code to record whatever fields you access out of a listenable class, and then use that information to listen to whenever those fields get modified by *any* Dart code.

This means that a pre-written class with a bunch of fields, can be instantly used in UI (with the help of some higher level abstractions e.g. `synaps_flutter`).

## What's different? What's new?

Here's a quick run-down of just the important additions in synaps

### `synaps`

#### Decorators

##### `@Controller()`

When a class is annotated with a @Controller, 
it gains the ability to host observable fields
This is done through a precompiled dart file that
converts every field in the class into a getter/setter.
The class then gains the `.toController()` and `.ctx()`
helper methods, both of which do the same thing.
These helpers convert a regular class into an observable
Controller class which can play nice with Synaps.

##### `@Observable()`
When a field of a @Controller class is marked with @Observable,
it gains the ability to track whenever that specific field is modified and/or read from. Internally, this gives hints to the `source_gen` generator to insert calls to the Synaps library to track field reads/writes

#### Classes / Methods

##### `Synaps`
The Synaps overseer

It contains some global state to keep track of every single
field write/read, and houses the Public API to consume
the read/write events.

##### `SynapsMonitorState Synaps.monitor({Function capture, Function onUpdate})` / alias: `Mx()`

NB: If you are using `synaps_flutter`, you will never need to directly use Synaps' public API.
See `Rx` below.

Calls the given function `capture`, and records any variable reads
while that function executes.

In the future, when any captured variable is updated by any code, `onUpdate`
will be called at most once per update/transaction

### `synaps_flutter`

#### Classes / Methods

##### Rx
A stateful widget that wraps Synaps.
It takes a build function as its constructor parameter.

In Flutter, UI = f(state);

If your state consists of one variable, then things stay simple.
However, if your state consists of multiple variables, like
nose color, facepaint color, honk loudness, etc. you end up with
`UI = f(var1,var2,var3,var4,...);`

Sometimes this is unavoidable. In the real world using other
solutions, it may be necessary to write extensive boilerplate code
to facilitate `f(var1,var2,...)`. Rx() instead opts to identify the
arguments of `f()` automatically, and hook setState up to changes
in any of the aforementioned arguments.

When the build method of the widget inside Rx() runs, Synaps
records any Observable() fields that were *accessed* by the
build method, and attaches listeners to each field. This means that whenever a field relevant to the build method is updated, 
setState() is called, invalidating the widget, and hinting to
Flutter that a rebuild would likely change the UI.

## Usage

Coming soon once the API is stable. Until then, if you are truly truly desperate, you can read through the example directories and the codebase, or if you are REALLY REALLY REALLY desperate, I am happy to answer your questions via the issue tracker in this repository.

## Examples / Breakdown

### Flutter

See `flutter_example\lib\main.dart`

```dart

import 'package:synaps_flutter/synaps_flutter.dart';

```

The first step to using synaps_flutter is to import the library.

```dart
// We need this for synaps' generators
part "main.g.dart";

// Define the counter class
@Controller()
class Counter {
  // Create an observable field for our int counter
  @Observable()
  int counter = 0;
```

Then, we need to define the state that is going to be glued. This can be
a logic class you have already written, or just a plain old description of data.
Importantly, we need to use `@Controller()` and `@Observable()` for synaps
to understand what you are trying to do.

```dart
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
```

Then, we need our application logic.
In this example, we have added our application logic directly to the counter controller.

Have you noticed it yet? The `Counter` class on its own does not depend on flutter at all.

You can easily run it in an environment without flutter (*COUGH* for testing *COUGH*).


```dart
class MyHomePage extends StatelessWidget {
  ...

  // Use .ctx() at the end to get an Observable Controller,
  // which internally manages all of Synaps' logic for you.
  final controller = Counter().ctx();

```

Then, we need to initialise the controller that you defined above. There are no
restrictions on where this should be done. You can initialise a controller into a 
global variable if you truly wanted to.

In this example, we have initialised the Counter into a StatelessWidget.
If you want to access this controller from a child widget, you can use whatever method you want
like InheritedWidgets, passing the controller as a constructor argument to a child widget, or
even just using global variables and importing it into the file you want to use it in.

Each method has its own strengths and weaknesses, the discussion of which is not in
the scope of this simple example.

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      ...
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
      floatingActionButton: Row(
        children: [
          FloatingActionButton(
            onPressed: controller.incrementCounter,     // just
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: controller.zeroCounter,          // like
            tooltip: 'Zero',
            child: Icon(Icons.settings_backup_restore),
          ),
          FloatingActionButton(
            onPressed: controller.decrementCounter,     // magic
            tooltip: 'Decrement',
            child: Icon(Icons.remove),
          ),
        ],
      ),
      ...

```

And finally, it's time to link it to our UI!

Our UI doesn't do the logic for adding and dividing, and it needs to speak with the Counter
to get the state it needs, and inform the Counter about the operations it needs to do.

Just use `controller` as you would naturally. This library is meant to be used intuitively.
Everything is converted into setState() under the hood.

This means that when the `Counter.counter` field is updated, the ONLY widget that receives a setState
is the Rx() widget that contains `Counter.counter`! Granular UI updates. Isn't that amazing?

### Under the hood

A simple usage example, for the people who are interested in how it looks under the hood:

`example_controller.dart`
```dart

import "package:synaps/synaps.dart";

part "example_controller.g.dart";

@Controller()
class Counter {
  @Observable()
  int clk = 0;
}

```

`synaps_example.dart`
```dart
import "package:synaps/synaps.dart";

import "example_controller.dart";

void someOtherFunc(Counter counter) {
  counter.clk++;
}

void main() {
  // Basic program that prints the value of a changing int

  final counter = Counter().ctx();

  Synaps.monitor(
    capture: () {
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

```

(And for the truly interested, here's what's inside `example_controller.g.dart`)

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_controller.dart';

// **************************************************************************
// ObservableGenerator
// **************************************************************************

class _CounterController extends Counter with SynapsControllerInterface {
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
```

## Features and bugs

Please file feature requests and bugs at the issue tracker.
