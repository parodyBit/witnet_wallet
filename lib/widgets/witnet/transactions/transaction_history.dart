import 'package:flutter/material.dart';
import 'package:witnet_wallet/util/witnet/wallet/account.dart';

import '../../vtt_list.dart';

class TransactionHistory extends StatelessWidget {
  final ThemeData themeData;
  Map<String, Account> externalAccounts;
  Map<String, Account> internalAccounts;
  TransactionHistory(
      {required this.themeData,
      required this.externalAccounts,
      required this.internalAccounts});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    List<VttListItem> vtts = [];
    externalAccounts.forEach((addr, acc) {
      acc.valueTransfers.forEach((trxHash, vti) {
        vtts.add(VttListItem(vti));
      });
    });

    return Container(
      color: Colors.white,
      width: size.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            child: Text(
              'Transaction History:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
              padding: EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  VttListWidget(
                    accounts: externalAccounts,
                    width: 300,
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
