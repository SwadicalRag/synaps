library synaps;

export 'package:synaps/synaps.dart';

import 'package:flutter/widgets.dart';
import 'package:synaps/synaps.dart';

/// A stateful widget that wraps Synaps
/// It takes a build function as its constructor parameter.
/// 
/// In Flutter, UI = f(state);
/// 
/// If your state consists of one variable, then things are simple
/// However, if your state consists of multiple variables, like
/// nose color, facepaint color, honk loudness, etc. you end up with
/// `UI = f(var1,var2,var3,var4,...);`
/// 
/// Sometimes this is unavoidable. In the real world, using other
/// solutions, it may be necessary to write extensive boilerplate code
/// to facilitate `f(var1,var2,...)`. Rx() instead opts to identify the
/// arguments of `f()` automatically, and hook setState up to changes
/// in any of the aforementioned arguments.
/// 
/// When the build method of the widget inside Rx() runs, Synaps
/// records any Observable() fields that were *accessed* by the
/// build method, and attaches listeners to each field. This means that
/// whenever a field relevant to the build method is updated, 
/// setState() is called, invalidating the widget, and hinting to
/// Flutter that a rebuild would likely change the UI.
/// 
class Rx extends StatefulWidget {
  final Widget Function() _buildFunc;

  Rx(this._buildFunc);

  RxState createState() => RxState();
}

class RxState extends State<Rx> {
  SynapsMonitorState _monitorState;

  @override
  dispose() {
    if(_monitorState != null) {
      _monitorState.dispose();
      _monitorState = null;
    }
    super.dispose();
  }

  Widget build(BuildContext context) {
    if(_monitorState != null) {
      _monitorState.dispose();
      _monitorState = null;
    }

    Widget out;

    _monitorState = Synaps.monitor(
      capture: () {
        out = widget._buildFunc();
      },
      onUpdate: () {
        // Run setState to mark this widget for a re-build
        if (mounted) {
          this.setState(() {});
        }
      }
    );

    if(!_monitorState.hasCapturedSymbols) {
      throw """
      [synaps_flutter] No observable variables were detected directly inside this widget.
      Several common issues that lead to this error include:
      1. Not using .ctx()/.toController() on @Controller() classes
      2. Not using any @Controller() classes inside this Rx() widget
      3. The field being accessed was not marked with @Observable()
      4. The field is being accessed *asynchronously* and/or *after* the build function has
          returned a value. It does not make sense to update a widget because of a field that
          does not participate in the making of the return value of this build method
      """;
    }

    return out;
  }
}
