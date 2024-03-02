import 'package:cursor_selectable_container/bounding_box.dart';

class SelectableData<T> {
  final T data;
  final BoundingBox bbox;

  SelectableData({required this.data, required this.bbox});
}