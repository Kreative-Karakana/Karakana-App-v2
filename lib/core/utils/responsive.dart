import 'package:flutter/widgets.dart';

class Responsive {
  static double h(BuildContext context, double percent) =>
      MediaQuery.of(context).size.height * percent;

  static double w(BuildContext context, double percent) =>
      MediaQuery.of(context).size.width * percent;

  static double topPadding(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  static double bottomPadding(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;
}
