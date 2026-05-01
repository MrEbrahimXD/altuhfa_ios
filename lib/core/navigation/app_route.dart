import 'package:flutter/material.dart';

class AppRoute<T> extends MaterialPageRoute<T> {
  AppRoute({required Widget page, super.settings})
      : super(builder: (context) => page);
}
