library synaps;

export 'package:synaps/synaps.dart';

import 'package:flutter/rendering.dart';
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
  SynapsMonitorState? _monitorState;

  @override
  dispose() {
    if(_monitorState != null) {
      _monitorState!.dispose();
      _monitorState = null;
    }
    super.dispose();
  }

  Widget build(BuildContext context) {
    if(_monitorState != null) {
      _monitorState!.dispose();
      _monitorState = null;
    }

    late Widget out;

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

    if(!_monitorState!.hasCapturedSymbols) {
      throw """
      [synaps_flutter] No observable variables were detected directly inside this widget.
      Several common issues that lead to this error include:
      1. Not using .ctx()/.toController() on @Controller() classes
      2. Not using any @Controller() classes inside this Rx() widget
      3. The field being accessed was not marked with @Observable()
      4. The generated dart file is outdated after new changes to the controller class (like adding
          a new @Observable() declaration)
      5. The field is being accessed *asynchronously* and/or *after* the build function has
          returned a value. It does not make sense to update a widget because of a field that
          does not participate in the making of the return value of this build method
      """;
    }

    return out;
  }
}


/// A CustomPaint widget that wraps Synaps
/// It is a "drop in" replacement for CustomPaint
/// 
/// It will intelligently capture any @Observables used inside the
/// paint methods of any CustomPainters that this widget accepts, and
/// will intelligently mark this widget for a re-paint if any @Observables
/// are updated.
/// 
/// With `allowEmptyCaptures` is set to false, this widget will throw errors
/// if @Observables() were unable to be captured inside the paint method.
/// 
class RxCustomPaint extends CustomPaint {
  final bool allowEmptyCaptures;

  RxCustomPaint({
    this.allowEmptyCaptures = false,
    Key? key,
    CustomPainter? painter,
    CustomPainter? foregroundPainter,
    size = Size.zero,
    isComplex = false,
    willChange = false,
    Widget? child,
  }) : super(
    key: key,
    painter: painter,
    foregroundPainter: foregroundPainter,
    size: size,
    isComplex: isComplex,
    willChange: willChange,
    child: child,
  );

  @override
  RenderCustomPaint createRenderObject(BuildContext context) {
    return _RxRenderCustomPaint(
      allowEmptyCaptures: allowEmptyCaptures,
      painter: painter,
      foregroundPainter: foregroundPainter,
      preferredSize: size,
      isComplex: isComplex,
      willChange: willChange,
    );
  }
}

class _RxRenderCustomPaint extends RenderCustomPaint {
  SynapsMonitorState? _monitorState;
  final bool? allowEmptyCaptures;

  _RxRenderCustomPaint({
    this.allowEmptyCaptures,
    CustomPainter? painter,
    CustomPainter? foregroundPainter,
    preferredSize = Size.zero,
    isComplex = false,
    willChange = false,
    RenderBox? child,
  }) : super(
    painter: painter,
    foregroundPainter: foregroundPainter,
    preferredSize: preferredSize,
    isComplex: isComplex,
    willChange: willChange,
    child: child,
  );

  @override
  void detach() {
    super.detach();
    if(_monitorState != null) {
      _monitorState!.dispose();
      _monitorState = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if(_monitorState != null) {
      _monitorState!.dispose();
      _monitorState = null;
    }

    _monitorState = Synaps.monitor(
      capture: () {
        // Capture any observables inside the original paint method
        super.paint(context,offset);
      },
      onUpdate: () {
        // Mark this RenderObject for a re-paint if any observables change
        this.markNeedsPaint();
      }
    );

    if(!_monitorState!.hasCapturedSymbols && (allowEmptyCaptures != true)) {
      throw """
      [synaps_flutter] No observable variables were detected directly inside this CustomPainter.
      Several common issues that lead to this error include:
      1. Not using .ctx()/.toController() on @Controller() classes
      2. Not using any @Controller() classes inside the paint() method of this CustomPainter
      3. The field being accessed was not marked with @Observable()
      4. The generated dart file is outdated after new changes to the controller class (like adding
          a new @Observable() declaration)
      5. The field is being accessed *asynchronously* and/or *after* the paint() function has
          returned. It does not make sense to update a CustomPainter because of a field that
          does not directly participate in the render of this canvas
      6. There is a region of code that accesses an @Observable() field, but it was not evaluated
          (maybe because it is inside a conditional block that was not evaluated). Synaps cannot
          detect @Observables() from regions of code that were not executed. Therefore, it may not
          know when to re-paint this custom widget. If this is intentional, this error can be 
          bypassed by setting `allowEmptyCaptures` to `true` in the CustomPaint constructor.
      """;
    }
  }
}
