import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_wit_wallet/bloc/transactions/value_transfer/vtt_create/vtt_create_bloc.dart';
import 'package:my_wit_wallet/screens/dashboard/view/dashboard_screen.dart';
import 'package:my_wit_wallet/shared/api_database.dart';
import 'package:my_wit_wallet/shared/locator.dart';
import 'package:my_wit_wallet/theme/extended_theme.dart';
import 'package:my_wit_wallet/util/get_localization.dart';
import 'package:my_wit_wallet/util/storage/database/adapters/transaction_adapter.dart';

import 'package:my_wit_wallet/widgets/buttons/custom_btn.dart';
import 'package:my_wit_wallet/widgets/closable_view.dart';
import 'package:my_wit_wallet/widgets/layouts/send_transaction_layout.dart';
import 'package:my_wit_wallet/widgets/witnet/transactions/value_transfer/create_dialog_box/vtt_builder/02_select_miner_fee.dart';
import 'package:my_wit_wallet/widgets/witnet/transactions/value_transfer/create_dialog_box/vtt_builder/03_review_step.dart';

typedef void VoidCallback();

class SpeedUpVtt extends StatefulWidget {
  final VoidCallback closeSetting;
  final GeneralTransaction speedUpTx;

  SpeedUpVtt({
    Key? key,
    required this.closeSetting,
    required this.speedUpTx,
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() => SpeedUpVttState();
}

class SpeedUpVttState extends State<SpeedUpVtt> {
  Map<String, dynamic>? signedMessage;
  ApiDatabase db = Locator.instance.get<ApiDatabase>();
  GlobalKey<SelectMinerFeeStepState> minerFeeState =
      GlobalKey<SelectMinerFeeStepState>();
  dynamic nextAction;
  bool selectMinerFeeStep = true;
  get isMinerFeeValid =>
      minerFeeState.currentState != null &&
      minerFeeState.currentState!.validateForm(force: true);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _setNextAction(action) {
    if (mounted) {
      setState(() {
        nextAction = action;
      });
    }
  }

  void showReviewStep() {
    setState(() => selectMinerFeeStep = false);
  }

  void goNext() {
    if (nextAction != null) {
      nextAction().action();
      if (isMinerFeeValid) showReviewStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ExtendedTheme extendedTheme = theme.extension<ExtendedTheme>()!;

    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (previous, current) {
        if (current.transactionStatus != TransactionStatus.initial) {
          return ClosableView(
              title: localization.speedUpTxTitle,
              closeSetting: widget.closeSetting,
              children: [
                SizedBox(height: 16),
                selectMinerFeeStep
                    ? SelectMinerFeeStep(
                        key: minerFeeState,
                        minFee: widget.speedUpTx.fee,
                        nextAction: _setNextAction,
                        goNext: goNext,
                        currentWallet: db.walletStorage.currentWallet,
                      )
                    : ReviewStep(
                        transactionType: TransactionType.Vtt,
                        originRoute: DashboardScreen.route,
                        nextAction: _setNextAction,
                        speedUpTx: widget.speedUpTx,
                        currentWallet: db.walletStorage.currentWallet,
                      ),
                SizedBox(height: 16),
                CustomButton(
                    padding: EdgeInsets.zero,
                    text: localization.continueLabel,
                    type: CustomBtnType.primary,
                    enabled: true,
                    onPressed: goNext)
              ]);
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
                      SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(
                            color: extendedTheme.spinnerColor,
                            strokeWidth: 2,
                            value: null,
                            semanticsLabel: localization.loading,
                          )),
                      SizedBox(
                        height: 24,
                      ),
                    ]),
              )
            ],
          );
        }
      },
    );
  }
}
