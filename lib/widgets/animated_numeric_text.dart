import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedNumericText extends StatelessWidget {
  AnimatedNumericText({
    Key? key,
    required this.initialValue,
    required this.targetValue,
    required this.controller,
    this.curve = Curves.linear,
    this.formatter = '#,##0.000000000',
    required this.style,
  })  : numberFormat = NumberFormat(formatter),
        numberAnimation = Tween<double>(
          begin: initialValue,
          end: targetValue,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: curve,
        )),
        super(key: key);

  final double initialValue;
  final double targetValue;
  final AnimationController controller;
  final Curve curve;
  final String formatter;
  final TextStyle style;
  final numberFormat;
  final Animation<double> numberAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: numberAnimation,
      builder: (context, child) => Text(
        '${numberFormat.format(numberAnimation.value)}',
        style: style,
      ),
    );
  }
}

class AnimatedIntegerText extends StatelessWidget {
  AnimatedIntegerText({
    Key? key,
    required this.initialValue,
    required this.targetValue,
    required this.controller,
    this.curve = Curves.linear,
    this.formatter = '#,###',
    required this.style,
  })  : numberFormat = NumberFormat(formatter),
        numberAnimation = IntTween(
          begin: initialValue,
          end: targetValue,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: curve,
        )),
        super(key: key);

  final int initialValue;
  final int targetValue;
  final AnimationController controller;
  final Curve curve;
  final String formatter;
  final TextStyle style;
  final numberFormat;
  final Animation<int> numberAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: numberAnimation,
      builder: (context, child) => Text(
        '${numberFormat.format(numberAnimation.value)}',
        style: style,
      ),
    );
  }
}
