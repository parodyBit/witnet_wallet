import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_wit_wallet/bloc/crypto/crypto_bloc.dart';
import 'package:my_wit_wallet/bloc/explorer/explorer_bloc.dart';
import 'package:my_wit_wallet/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:my_wit_wallet/screens/login/bloc/login_bloc.dart';
import 'package:my_wit_wallet/screens/preferences/preferences_screen.dart';
import 'package:my_wit_wallet/theme/extended_theme.dart';
import 'package:my_wit_wallet/util/preferences.dart';
import 'package:my_wit_wallet/widgets/PaddedButton.dart';
import 'package:my_wit_wallet/widgets/custom_divider.dart';
import 'package:my_wit_wallet/widgets/switch.dart';
import 'package:my_wit_wallet/bloc/theme/theme_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_wit_wallet/theme/wallet_theme.dart';
import 'package:my_wit_wallet/constants.dart';
import 'package:my_wit_wallet/widgets/witnet/transactions/value_transfer/modals/unlock_keychain_modal.dart';

enum AuthPreferences { Password, Biometrics }

class GeneralConfig extends StatefulWidget {
  GeneralConfig({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => GeneralConfigState();
}

class GeneralConfigState extends State<GeneralConfig> {
  bool displayDarkMode = false;
  bool authWithBiometrics = false;
  FocusNode _switchThemeFocusNode = FocusNode();
  bool _isThemeSwitchFocus = false;
  FocusNode _switchAuthModeFocusNode = FocusNode();
  bool _isAuthModeSwitchFocus = false;

  AppLocalizations get _localization => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _switchThemeFocusNode.addListener(_handleFocus);
    _getTheme();
    _getAuthPreferences();
  }

  @override
  void dispose() {
    _switchThemeFocusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    setState(() {
      _isThemeSwitchFocus = _switchThemeFocusNode.hasFocus;
    });
  }

  Future<void> _getTheme() async {
    String? theme = await ApiPreferences.getTheme();
    if (theme != null && theme == WalletTheme.Dark.name) {
      setState(() {
        displayDarkMode = true;
      });
    } else {
      setState(() {
        displayDarkMode = false;
      });
    }
  }

  Future<void> _getAuthPreferences() async {
    String? authPreferences = await ApiPreferences.getAuthPreferences();
    if (authPreferences != null &&
        authPreferences == AuthPreferences.Biometrics.name) {
      setState(() {
        authWithBiometrics = true;
      });
    } else {
      setState(() {
        authWithBiometrics = false;
      });
    }
  }

  Widget themeWidget(ThemeData theme, BuildContext context) {
    return backgroundBox(
      theme: theme,
      context: context,
      child: CustomSwitch(
          focusNode: _switchThemeFocusNode,
          isFocused: _isThemeSwitchFocus,
          checked: displayDarkMode,
          primaryLabel: _localization.darkMode,
          secondaryLabel: _localization.lightMode,
          onChanged: (value) => {
                setState(() {
                  displayDarkMode = !displayDarkMode;
                  final theme =
                      displayDarkMode ? WalletTheme.Dark : WalletTheme.Light;
                  ApiPreferences.setTheme(theme);
                  BlocProvider.of<ThemeBloc>(context).add(ThemeChanged(theme));
                })
              }),
    );
  }

  Widget backgroundBox(
      {required ThemeData theme,
      required BuildContext context,
      required Widget child}) {
    final extendedTheme = theme.extension<ExtendedTheme>()!;
    return Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
          color: extendedTheme.backgroundBox,
        ),
        child: child);
  }

  void changeAuthMode(ThemeData theme) {
    setState(() {
      authWithBiometrics = !authWithBiometrics;
      final authMode = authWithBiometrics
          ? AuthPreferences.Biometrics
          : AuthPreferences.Password;
      ApiPreferences.setAuthPreferences(authMode);
    });
  }

  Widget biometricsAuth(ThemeData theme, BuildContext context) {
    return backgroundBox(
        theme: theme,
        context: context,
        child: CustomSwitch(
            focusNode: _switchAuthModeFocusNode,
            isFocused: _isAuthModeSwitchFocus,
            checked: authWithBiometrics,
            primaryLabel: 'Biometrics',
            secondaryLabel: '',
            onChanged: (value) => {
                  if (!value)
                    {
                      unlockKeychainModal(
                          onAction: () => changeAuthMode(theme),
                          title: 'Enter your password',
                          imageName: 'import-wallet',
                          theme: theme,
                          context: context,
                          routeToRedirect: PreferencePage.route)
                    }
                  else
                    {
                      changeAuthMode(theme),
                    }
                }));
  }

  //Log out
  void _logOut() {
    BlocProvider.of<ExplorerBloc>(context)
        .add(CancelSyncWalletEvent(ExplorerStatus.unknown));
    BlocProvider.of<DashboardBloc>(context).add(DashboardResetEvent());
    BlocProvider.of<CryptoBloc>(context).add(CryptoReadyEvent());
    Navigator.of(context).popUntil((route) => route.isFirst);
    BlocProvider.of<LoginBloc>(context).add(LoginLogoutEvent());
  }

  List<Widget> showAuthModeSettings(ThemeData theme) {
    if ((Platform.isAndroid || Platform.isIOS)) {
      return [
        SizedBox(height: 8),
        CustomDivider(),
        Text(
          'Enable login with biometrics',
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: 16),
        biometricsAuth(theme, context),
        SizedBox(height: 16)
      ];
    } else {
      return [SizedBox(height: 16)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: EdgeInsets.only(left: 8, right: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 32),
          Text(
            _localization.theme,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 16),
          themeWidget(theme, context),
          ...showAuthModeSettings(theme),
          CustomDivider(),
          Text(
            _localization.lockYourWallet,
            style: theme.textTheme.titleMedium,
          ),
          PaddedButton(
              padding: EdgeInsets.only(bottom: 16, top: 16),
              text: _localization.lockWalletLabel,
              type: ButtonType.primary,
              enabled: true,
              onPressed: () => _logOut()),
          SizedBox(height: 16),
          Text(
            _localization.versionNumber(VERSION_NUMBER),
            style: theme.textTheme.titleSmall,
          )
        ]));
  }
}
