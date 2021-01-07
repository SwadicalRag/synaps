library synaps;

export 'package:synaps/synaps.dart';

import 'package:flutter/widgets.dart';
import 'package:synaps/synaps.dart';

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
      Are you sure you are using Rx() correctly?
      """;
    }

    return out;
  }
}
