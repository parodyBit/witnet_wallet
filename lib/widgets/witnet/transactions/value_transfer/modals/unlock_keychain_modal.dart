import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_wit_wallet/bloc/transactions/value_transfer/vtt_create/vtt_create_bloc.dart';
import 'package:my_wit_wallet/screens/dashboard/view/dashboard_screen.dart';
import 'package:my_wit_wallet/screens/login/view/password_validate.dart';
import 'package:my_wit_wallet/screens/send_transaction/send_vtt_screen.dart';
import 'package:my_wit_wallet/shared/api_database.dart';
import 'package:my_wit_wallet/shared/locator.dart';
import 'package:my_wit_wallet/theme/wallet_theme.dart';
import 'package:my_wit_wallet/widgets/PaddedButton.dart';
import 'package:my_wit_wallet/widgets/layouts/dashboard_layout.dart';

Future<String?> unlockKeychainModal(
    {required ThemeData theme,
    required BuildContext context,
    required String routeToRedirect}) {
  return Future.delayed(
      Duration.zero,
      () => showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            String _password = '';
            String? _passwordInputErrorText;
            return StatefulBuilder(builder: (context, setState) {
              void _updatePassword({required String password}) {
                _password = password;
              }

              void _clearError() {
                setState(() => _passwordInputErrorText = null);
              }

              Future<void> _login(
                  {required bool validate, required String password}) async {
                ApiDatabase apiDatabase = Locator.instance<ApiDatabase>();
                _password = password;
                try {
                  if (validate) {
                    bool valid = await apiDatabase.verifyPassword(password);
                    if (!valid) {
                      setState(
                          () => _passwordInputErrorText = 'Invalid password');
                    } else {
                      Navigator.popUntil(
                          context, ModalRoute.withName(routeToRedirect));
                      ScaffoldMessenger.of(context).clearSnackBars();
                      BlocProvider.of<VTTCreateBloc>(context)
                          .add(ResetTransactionEvent());
                    }
                  }
                } catch (err) {
                  rethrow;
                }
              }

              return AlertDialog(
                title: Text(
                  'Input your password to send a transaction',
                  style: theme.textTheme.displayMedium,
                ),
                backgroundColor: theme.colorScheme.background,
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  svgThemeImage(theme,
                      name: 'sending-transaction', height: 100),
                  SizedBox(height: 16),
                  PasswordValidation(
                    validate: _login,
                    passwordUpdates: _updatePassword,
                    clearError: _clearError,
                    passwordInputErrorText: _passwordInputErrorText,
                  )
                ]),
                actions: [
                  PaddedButton(
                      padding: EdgeInsets.only(right: 8),
                      text: 'Close',
                      type: ButtonType.text,
                      color: theme.textTheme.bodyLarge!.color,
                      enabled: true,
                      onPressed: () => {
                            Navigator.popUntil(
                                context, ModalRoute.withName(routeToRedirect)),
                            ScaffoldMessenger.of(context).clearSnackBars(),
                            if (routeToRedirect == CreateVttScreen.route)
                              {
                                Navigator.pushReplacement(
                                    context,
                                    CustomPageRoute(
                                        builder: (BuildContext context) {
                                          return DashboardScreen();
                                        },
                                        maintainState: false,
                                        settings: RouteSettings(
                                            name: DashboardScreen.route)))
                              }
                          }),
                  PaddedButton(
                      padding: EdgeInsets.only(top: 0),
                      text: 'Continue',
                      type: ButtonType.text,
                      enabled: true,
                      onPressed: () =>
                          {_login(validate: true, password: _password)})
                ],
              );
            });
          }));
}
