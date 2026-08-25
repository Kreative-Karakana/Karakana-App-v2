import 'package:flutter/widgets.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  static double h(BuildContext context, double percent) =>
      MediaQuery.of(context).size.height * percent;

  static double w(BuildContext context, double percent) =>
      MediaQuery.of(context).size.width * percent;

  static double topPadding(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  static double bottomPadding(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;
}
