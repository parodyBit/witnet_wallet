import 'package:flutter/material.dart';
import 'package:my_wit_wallet/util/get_localization.dart';
import 'package:my_wit_wallet/theme/wallet_theme.dart';
import 'package:my_wit_wallet/widgets/alert_dialog.dart';

void buildSigningTxModal(ThemeData theme, BuildContext context) {
  return buildAlertDialog(
      context: context,
      actions: [],
      title: localization.txnSigning,
      image: svgThemeImage(theme, name: 'sending-transaction', height: 100),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(localization.txnSigning01, style: theme.textTheme.bodyLarge)
      ]));
}
