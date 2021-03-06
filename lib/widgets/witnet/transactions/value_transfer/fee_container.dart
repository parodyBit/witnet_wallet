import 'package:flutter/material.dart';
import 'package:witnet/utils.dart';

import '../../../auto_size_text.dart';

class FeeContainer extends StatelessWidget {
  FeeContainer({
    required this.feeValue,
  });
  final int feeValue;
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    double cardWidth;
    if (deviceSize.width > 400) {
      cardWidth = (400 * 0.7);
    } else
      cardWidth = deviceSize.width * 0.7;
    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(3),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 3,
              ),
              Expanded(
                  flex: 9,
                  child: AutoSizeText(
                    'Network Fee',
                    maxLines: 1,
                    minFontSize: 9,
                  )),
              SizedBox(
                width: 3,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                  flex: 9,
                  child: AutoSizeText(
                    nanoWitToWit(feeValue).toStringAsFixed(9),
                    maxLines: 1,
                    minFontSize: 9,
                    textAlign: TextAlign.right,
                  )),
              SizedBox(
                width: 3,
              ),
              Expanded(
                flex: 1,
                child: Image.asset(
                  'assets/img/favicon.ico',
                ),
              ),
              SizedBox(
                width: 3,
              ),
              Expanded(
                  flex: 1,
                  child: AutoSizeText(
                    'WIT',
                    maxLines: 1,
                    minFontSize: 9,
                    textAlign: TextAlign.right,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
