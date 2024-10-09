import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_wit_wallet/bloc/transactions/value_transfer/vtt_create/vtt_create_bloc.dart';
import 'package:my_wit_wallet/screens/dashboard/view/dashboard_screen.dart';
import 'package:my_wit_wallet/screens/stake/stake_screen.dart';
import 'package:my_wit_wallet/screens/unstake/unstake_screen.dart';
import 'package:my_wit_wallet/shared/api_database.dart';
import 'package:my_wit_wallet/shared/locator.dart';
import 'package:my_wit_wallet/theme/extended_theme.dart';
import 'package:my_wit_wallet/theme/wallet_theme.dart';
import 'package:my_wit_wallet/util/current_route.dart';
import 'package:my_wit_wallet/util/get_localization.dart';
import 'package:my_wit_wallet/util/storage/database/balance_info.dart';
import 'package:my_wit_wallet/util/storage/database/wallet.dart';
import 'package:my_wit_wallet/widgets/PaddedButton.dart';
import 'package:my_wit_wallet/widgets/layouts/dashboard_layout.dart';
import 'package:flutter/material.dart';
import 'package:my_wit_wallet/widgets/witnet/transactions/value_transfer/modals/empty_stake_modal.dart';

typedef void VoidCallback();

class StakeUnstakeButtons extends StatelessWidget {
  StakeUnstakeButtons({Key? key}) : super(key: key);

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extendedTheme = theme.extension<ExtendedTheme>()!;
    ApiDatabase db = Locator.instance.get<ApiDatabase>();
    Wallet currentWallet = db.walletStorage.currentWallet;
    late StakedBalanceInfo stakeInfo = currentWallet.stakedNanoWit();

    Future<void> _goToStakeScreen() async {
      BlocProvider.of<TransactionBloc>(context).add(ResetTransactionEvent());
      Navigator.push(
          context,
          CustomPageRoute(
              builder: (BuildContext context) {
                return StakeScreen();
              },
              maintainState: false,
              settings: RouteSettings(name: StakeScreen.route)));
    }

    Future<void> _goToUnstakeScreen() async {
      BlocProvider.of<TransactionBloc>(context).add(ResetTransactionEvent());
      if (stakeInfo.stakedNanoWit > 0) {
        Navigator.push(
            context,
            CustomPageRoute(
                builder: (BuildContext context) {
                  return UnstakeScreen();
                },
                maintainState: false,
                settings: RouteSettings(name: UnstakeScreen.route)));
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        buildEmptyStakeModal(
            theme: theme,
            context: context,
            originRouteName: DashboardScreen.route,
            originRoute: DashboardScreen());
      }
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),
          PaddedButton(
            color: extendedTheme.mediumPanelText!.color,
            boldText: true,
            padding: EdgeInsets.only(left: 16, right: 16),
            text: localization.stake,
            onPressed: currentRoute(context) != StakeScreen.route
                ? _goToStakeScreen
                : () {},
            icon: Container(
                height: 40,
                child: svgThemeImage(theme, name: 'stake-icon', height: 18)),
            type: ButtonType.horizontalIcon,
            alignment: MainAxisAlignment.start,
            iconPosition: IconPosition.left,
          ),
          SizedBox(width: 16),
          PaddedButton(
            color: extendedTheme.mediumPanelText!.color,
            boldText: true,
            padding: EdgeInsets.only(left: 16, right: 16),
            text: localization.unstake,
            onPressed: currentRoute != UnstakeScreen.route
                ? _goToUnstakeScreen
                : () {},
            icon: Container(
                height: 40,
                child: svgThemeImage(theme, name: 'unstake-icon', height: 24)),
            type: ButtonType.horizontalIcon,
            alignment: MainAxisAlignment.start,
            iconPosition: IconPosition.left,
          ),
        ]);
  }
}
