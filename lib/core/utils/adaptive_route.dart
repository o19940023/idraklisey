import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart' show MaterialPageRoute, Route, WidgetBuilder;

Route<T> appRoute<T>({
  required WidgetBuilder builder,
  bool fullscreenDialog = false,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPageRoute<T>(
      builder: builder,
      fullscreenDialog: fullscreenDialog,
    );
  }
  return MaterialPageRoute<T>(
    builder: builder,
    fullscreenDialog: fullscreenDialog,
  );
}
