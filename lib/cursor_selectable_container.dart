library cursor_selectable_container;

import 'dart:io';

import 'package:cursor_selectable_container/selectable_data.dart';
import 'package:cursor_selectable_container/selection_adapter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dart:math' as math;

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'custom_image_view.dart';
import 'custom_selection_delegates.dart';


class CursorSelectableContainer extends StatelessWidget {
   CursorSelectableContainer({super.key, required this.image, required this.selectableData, required this.imageSize, required this.selectedData, this.onSelectionChanged,this.controls,this.textDirection,this.fixedContainerHeight});
  final String image;
  final List<SelectableData> selectableData;
  final Size imageSize;
  final String Function(Object value) selectedData;
  final Function(SelectedContent?)? onSelectionChanged;
  double? fixedContainerHeight;
  TextSelectionControls? controls;
  TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: imageSize);

    return Center(
      child: Container(
          width: imageSize.width.r,
          height: imageSize.height.r,
          // constraints: BoxConstraints(maxHeight: 1123.r,maxWidth:794.r ),

          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: imageSize.width.r,
              height: imageSize.height.r,
              decoration:  BoxDecoration(
                // color: Colors.amberAccent,
                image: DecorationImage(
                  image:buildImageView(image),
                ),
              ),
              child: SelectionTextWidget(imageSize: imageSize, selectableData: selectableData, selectedData: selectedData, onSelectionChanged: onSelectionChanged,),

            ),
          )),
    );
  }
}

class SelectionTextWidget extends StatelessWidget {
  // final String image;
  final List<SelectableData> selectableData;
  final Size imageSize;
  final String Function(Object value) selectedData;
  final Function(SelectedContent?)? onSelectionChanged;
  double? fixedContainerHeight;
  TextSelectionControls? controls;
  TextDirection? textDirection;

  SelectionTextWidget(
      {super.key,
      required this.imageSize,
      this.fixedContainerHeight,
      required this.selectableData,
      this.controls,
      required this.selectedData,
      required this.onSelectionChanged,
      });

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize:  imageSize);

    if (controls == null) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          controls = MaterialTextSelectionControls();
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          controls = CupertinoTextSelectionControls();
          break;
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          controls = EmptyTextSelectionControls();
          break;
      }
    }

    return SelectionArea(
      selectionControls: controls,
      onSelectionChanged: onSelectionChanged,

      child: SelectionContainer(
        delegate: CustomSelectionDelegate(textDirection),
        child: Stack(
          children: [
            ...selectableData.map((e) {
              double widthScaleFactor = imageSize.width.r / imageSize.width;
              double heightScaleFactor = imageSize.height.r / imageSize.height;
              double scaledLeft = e.bbox.x1 * widthScaleFactor;
              double scaledTop = e.bbox.y1 * heightScaleFactor;
              // double scaledRight = e.words.last.bbox.x2 * widthScaleFactor;
              final double lineHeight =
                  convertToLogicalPixels(context, (e.bbox.y2 - e.bbox.y1));

              return Positioned(
                height: fixedContainerHeight ?? lineHeight,
                top: scaledTop,
                left: scaledLeft,
                width: (e.bbox.x2.toDouble() - e.bbox.x1.toDouble()) /
                    (imageSize.width / (imageSize.width.r)),
                child:
                    textDirection == null || textDirection == TextDirection.ltr
                        ?MySelectableAdapter(
                      id: selectedData(e.data),
                      child: Container(),
                    ): Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(math.pi),
                            child: MySelectableAdapter(
                              id: selectedData(e.data),
                              child: Container(),
                            ),
                          )
                        ,
              );
            })
          ],
        ),
      ),
    );
  }
}

double convertToLogicalPixels(context, num pixels) {
  double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
  return pixels / devicePixelRatio;
}
