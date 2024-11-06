import 'package:flutter/material.dart';
import 'package:my_wit_wallet/shared/api_database.dart';
import 'package:my_wit_wallet/shared/locator.dart';
import 'package:my_wit_wallet/util/get_localization.dart';
import 'package:my_wit_wallet/util/storage/database/adapters/transaction_adapter.dart';
import 'package:my_wit_wallet/util/storage/database/wallet.dart';
import 'package:my_wit_wallet/theme/wallet_theme.dart';
import 'package:my_wit_wallet/widgets/transaction_item.dart';

typedef void VoidCallback(GeneralTransaction? value);
typedef void ShowPaginationCallback(bool value);

class TransactionsList extends StatefulWidget {
  final ThemeData themeData;
  final VoidCallback setDetails;
  final GeneralTransaction? details;
  final Wallet currentWallet;
  final List<GeneralTransaction> transactions;
  final ShowPaginationCallback showPagination;
  TransactionsList(
      {Key? key,
      required this.themeData,
      required this.details,
      required this.setDetails,
      required this.transactions,
      required this.showPagination,
      required this.currentWallet})
      : super(key: key);

  @override
  TransactionsListState createState() => TransactionsListState();
}

class TransactionsListState extends State<TransactionsList> {
  GeneralTransaction? transactionDetails;
  final ScrollController _scroller = ScrollController();
  GeneralTransaction? speedUpTransaction;
  Wallet currentWallet =
      Locator.instance.get<ApiDatabase>().walletStorage.currentWallet;
  dynamic nextAction;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.transactions.length > 0) {
      return ListView.builder(
        controller: _scroller,
        padding: EdgeInsets.only(top: 8),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        itemCount: widget.transactions.length,
        itemBuilder: (context, index) {
          GeneralTransaction transaction = widget.transactions[index];
          return TransactionsItem(
            transaction: transaction,
            showDetails: widget.setDetails,
            previousTxnTime:
                index > 0 ? widget.transactions[index - 1].txnTime : null,
          );
        },
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 24,
                  ),
                  svgThemeImage(theme, name: 'empty', height: 152),
                  SizedBox(
                    height: 24,
                  ),
                  Text(localization.txEmptyState)
                ]),
          )
        ],
      );
    }
  }
}
