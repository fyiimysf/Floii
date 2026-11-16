import 'package:flutter/widgets.dart';

const double _referenceWidth = 390;
const double _minFactor = 0.9;
const double _maxFactor = 1.1;

Widget buildAppTextScaling(BuildContext context, Widget? child) {
  if (child == null) return const SizedBox.shrink();
  final mq = MediaQuery.of(context);
  final factor =
      (mq.size.width / _referenceWidth).clamp(_minFactor, _maxFactor);
  final scale = mq.textScaler.scale(1) * factor;
  return MediaQuery(
    data: mq.copyWith(textScaler: TextScaler.linear(scale)),
    child: child,
  );
}
