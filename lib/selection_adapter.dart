import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [SelectableRegion].


class MySelectableAdapter extends StatelessWidget {
  const MySelectableAdapter({super.key, required this.child, required this.id});

  final Widget child;
  final String id;

  @override
  Widget build(BuildContext context) {
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);
    if (registrar == null) {
      return child;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: _SelectableAdapter(
        id: id,
        registrar: registrar,
        child: child,
      ),
    );
  }
}

class _SelectableAdapter extends SingleChildRenderObjectWidget {
  const _SelectableAdapter( {
    required this.id,
    required this.registrar,
    required Widget child,
  }) : super(child: child);

  final SelectionRegistrar registrar;
  final String id;

  @override
  _RenderSelectableAdapter createRenderObject(BuildContext context) {
    return _RenderSelectableAdapter(
        DefaultSelectionStyle.of(context).selectionColor!,
        registrar,
        id
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderSelectableAdapter renderObject) {
    renderObject
      ..selectionColor = DefaultSelectionStyle.of(context).selectionColor!
      ..registrar = registrar;
  }
}

class _RenderSelectableAdapter extends RenderProxyBox
    with Selectable, SelectionRegistrant {
  _RenderSelectableAdapter(
      Color selectionColor,
      SelectionRegistrar registrar, this.id,
      )   : _selectionColor = selectionColor,
        _geometry = ValueNotifier<SelectionGeometry>(_noSelection) {
    this.registrar = registrar;
    _geometry.addListener(markNeedsPaint);
  }

  final String id ;
  static const SelectionGeometry _noSelection =
  SelectionGeometry(status: SelectionStatus.none, hasContent: true);
  final ValueNotifier<SelectionGeometry> _geometry;

  Color get selectionColor => _selectionColor;
  late Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) {
      return;
    }
    _selectionColor = value;
    markNeedsPaint();
  }

  // ValueListenable APIs

  @override
  void addListener(VoidCallback listener) => _geometry.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _geometry.removeListener(listener);

  @override
  SelectionGeometry get value => _geometry.value;

  // Selectable APIs.

  @override
  List<Rect> get boundingBoxes => <Rect>[paintBounds];

  // Adjust this value to enlarge or shrink the selection highlight.
  static const double _padding = 0;
  Rect _getSelectionHighlightRect() {
    return Rect.fromLTWH(0 - _padding, 0 - _padding, size.width + _padding * 2,
        size.height + _padding * 2);
  }

  Offset? _start;
  Offset? _end;
  void _updateGeometry() {
    if (_start == null || _end == null) {
      _geometry.value = _noSelection;
      return;
    }
    final Rect renderObjectRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Rect selectionRect = Rect.fromPoints( _end!,_start!);
    if (renderObjectRect.intersect(selectionRect).isEmpty) {
      _geometry.value = _noSelection;
    } else {
      final Rect selectionRect = _getSelectionHighlightRect();
      final SelectionPoint firstSelectionPoint = SelectionPoint(
        localPosition: selectionRect.bottomRight,
        lineHeight: selectionRect.size.height,
        handleType: TextSelectionHandleType.right,
      );
      final SelectionPoint secondSelectionPoint = SelectionPoint(
        localPosition: selectionRect.bottomLeft,
        lineHeight: selectionRect.size.height,
        handleType: TextSelectionHandleType.left,
      );
      final bool isReversed;
      if (_start!.dy > _end!.dy) {
        isReversed = true;
      } else if (_start!.dy < _end!.dy) {
        isReversed = false;
      } else {
        isReversed = _start!.dx > _end!.dx;
      }
      _geometry.value = SelectionGeometry(
        status: SelectionStatus.uncollapsed,
        hasContent: true,
        startSelectionPoint:
        isReversed ? secondSelectionPoint : firstSelectionPoint,
        endSelectionPoint:
        isReversed ? firstSelectionPoint : secondSelectionPoint,
        selectionRects: <Rect>[selectionRect],
      );

      // print(_geometry.value.startSelectionPoint);
      // print(_geometry.value.);

    }
  }




  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    SelectionResult result = SelectionResult.none;
    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
      case SelectionEventType.endEdgeUpdate:
        final Rect renderObjectRect =
        Rect.fromLTWH(0, 0, size.width, size.height);
        // Normalize offset in case it is out side of the rect.
        final Offset point =
        globalToLocal((event as SelectionEdgeUpdateEvent).globalPosition);
        final Offset adjustedPoint =
        SelectionUtils.adjustDragOffset(renderObjectRect, point);
        if (event.type == SelectionEventType.startEdgeUpdate) {
          _start = adjustedPoint;
        } else {
          _end = adjustedPoint;
        }
        result = SelectionUtils.getResultBasedOnRect(renderObjectRect, point);
      case SelectionEventType.clear:
        _start = _end = null;
      case SelectionEventType.selectAll:
      case SelectionEventType.selectWord:
        _start = Offset.zero;
        _end = Offset.infinite;
      case SelectionEventType.granularlyExtendSelection:
        result = SelectionResult.end;
        final GranularlyExtendSelectionEvent extendSelectionEvent =
        event as GranularlyExtendSelectionEvent;
        // Initialize the offset it there is no ongoing selection.
        if (_start == null || _end == null) {
          if (extendSelectionEvent.forward) {
            _start = _end = Offset.zero;
          } else {
            _start = _end = Offset.infinite;
          }
        }
        // Move the corresponding selection edge.
        final Offset newOffset =
        extendSelectionEvent.forward ? Offset.infinite : Offset.zero;
        if (extendSelectionEvent.isEnd) {
          if (newOffset == _end) {
            result = extendSelectionEvent.forward
                ? SelectionResult.next
                : SelectionResult.previous;
          }
          _end = newOffset;
        } else {
          if (newOffset == _start) {
            result = extendSelectionEvent.forward
                ? SelectionResult.next
                : SelectionResult.previous;
          }
          _start = newOffset;
        }
      case SelectionEventType.directionallyExtendSelection:
        result = SelectionResult.end;
        final DirectionallyExtendSelectionEvent extendSelectionEvent =
        event as DirectionallyExtendSelectionEvent;
        // Convert to local coordinates.
        final double horizontalBaseLine = globalToLocal(Offset(event.dx, 0)).dx;
        final Offset newOffset;
        final bool forward;
        switch (extendSelectionEvent.direction) {
          case SelectionExtendDirection.backward:
          case SelectionExtendDirection.previousLine:
            forward = false;
            // Initialize the offset it there is no ongoing selection.
            if (_start == null || _end == null) {
              _start = _end = Offset.infinite;
            }
            // Move the corresponding selection edge.
            if (extendSelectionEvent.direction ==
                SelectionExtendDirection.previousLine ||
                horizontalBaseLine < 0) {
              newOffset = Offset.zero;
            } else {
              newOffset = Offset.infinite;
            }
          case SelectionExtendDirection.nextLine:
          case SelectionExtendDirection.forward:
            forward = true;
            // Initialize the offset it there is no ongoing selection.
            if (_start == null || _end == null) {
              _start = _end = Offset.zero;
            }
            // Move the corresponding selection edge.
            if (extendSelectionEvent.direction ==
                SelectionExtendDirection.nextLine ||
                horizontalBaseLine > size.width) {
              newOffset = Offset.infinite;
            } else {
              newOffset = Offset.zero;
            }
        }
        if (extendSelectionEvent.isEnd) {
          if (newOffset == _end) {
            result = forward ? SelectionResult.next : SelectionResult.previous;
          }
          _end = newOffset;
        } else {
          if (newOffset == _start) {
            result = forward ? SelectionResult.next : SelectionResult.previous;
          }
          _start = newOffset;
        }
    }
    _updateGeometry();
    return result;
  }

  // This method is called when users want to copy selected content in this
  // widget into clipboard.
  @override
  SelectedContent? getSelectedContent() {
    return value.hasSelection
        ?  SelectedContent(plainText:id)
        : null;
  }

  LayerLink? _startHandle;
  LayerLink? _endHandle;

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    if (_startHandle == startHandle && _endHandle == endHandle) {
      return;
    }
    _startHandle = startHandle;
    _endHandle = endHandle;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (!_geometry.value.hasSelection) {
      return;
    }
    // Draw the selection highlight.
    final Paint selectionPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _selectionColor;
    context.canvas
        .drawRect(_getSelectionHighlightRect().shift(offset), selectionPaint);

    // Push the layer links if any.
    if (_startHandle != null) {
      context.pushLayer(
        LeaderLayer(
          link: _startHandle!,
          offset: offset + value.startSelectionPoint!.localPosition,
        ),
            (PaintingContext context, Offset offset) {},
        Offset.zero,
      );
    }
    if (_endHandle != null) {
      context.pushLayer(
        LeaderLayer(
          link: _endHandle!,
          offset: offset + value.endSelectionPoint!.localPosition,
        ),
            (PaintingContext context, Offset offset) {},
        Offset.zero,
      );
    }
  }

  @override
  void dispose() {
    _geometry.dispose();
    super.dispose();
  }
}
