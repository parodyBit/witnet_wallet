import 'package:my_wit_wallet/util/get_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_wit_wallet/screens/create_wallet/bloc/api_create_wallet.dart';
import 'package:my_wit_wallet/screens/create_wallet/nav_action.dart';
import 'package:my_wit_wallet/shared/locator.dart';
import 'package:my_wit_wallet/util/storage/database/wallet.dart';
import 'package:my_wit_wallet/widgets/inputs/input_mnemonic.dart';
import 'package:my_wit_wallet/widgets/styled_text_controller.dart';
import 'package:witnet/crypto.dart';

import 'bloc/create_wallet_bloc.dart';

typedef void VoidCallback(NavAction? value);

class EnterMnemonicCard extends StatefulWidget {
  final Function nextAction;
  final Function prevAction;

  EnterMnemonicCard({
    Key? key,
    required VoidCallback this.nextAction,
    required VoidCallback this.prevAction,
  }) : super(key: key);

  EnterMnemonicCardState createState() => EnterMnemonicCardState();
}

class EnterMnemonicCardState extends State<EnterMnemonicCard>
    with TickerProviderStateMixin {
  String mnemonic = '';
  final StyledTextController styledTextController =
      StyledTextController(wordCheck: true);
  final mnemonicFocusNode = FocusNode();
  int numLines = 0;

  Widget _buildConfirmField() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          localization.importMnemonicHeader,
          style: theme.textTheme.titleLarge, //Textstyle
        ), //Text
        SizedBox(
          height: 16,
        ),
        Text(
          localization.importMnemonic01,
          style: theme.textTheme.bodyLarge, //Textstyle
        ), //Text
        SizedBox(
          height: 16,
        ),
        InputMnemonic(
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.go,
          hint: "enter recovery phrase.",
          maxLines: 4,
          styledTextController: styledTextController,
          onFieldSubmitted: (value) => {
            if (validMnemonic(styledTextController.value.text)) {nextAction()}
          },
          onChanged: (String e) {
            if (validMnemonic(styledTextController.value.text)) {
              widget.nextAction(next);
            } else {
              widget.nextAction(null);
            }
            setState(() {
              mnemonic = styledTextController.value.text;
              numLines = '\n'.allMatches(e).length + 1;
            });
          },
          onTapOutside: (event) {
            mnemonicFocusNode.unfocus();
          },
          focusNode: mnemonicFocusNode,
        ),
      ],
    );
  }

  void prevAction() {
    CreateWalletType type =
        BlocProvider.of<CreateWalletBloc>(context).state.createWalletType;
    BlocProvider.of<CreateWalletBloc>(context).add(PreviousCardEvent(type));
  }

  void nextAction() {
    Locator.instance<ApiCreateWallet>().setSeed(mnemonic, 'mnemonic');
    Locator.instance<ApiCreateWallet>().setWalletType(WalletType.hd);
    BlocProvider.of<CreateWalletBloc>(context).add(NextCardEvent(
        Locator.instance<ApiCreateWallet>().createWalletType,
        data: {}));
  }

  NavAction prev() {
    return NavAction(
      label: localization.backLabel,
      action: prevAction,
    );
  }

  NavAction next() {
    return NavAction(
      label: localization.continueLabel,
      action: nextAction,
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.prevAction(prev));
    super.initState();
  }

  bool validMnemonic(String mnemonic) {
    List<String> words = mnemonic.split(' ');
    int wordCount = words.length;
    List<int> validMnemonicLengths = [12, 15, 18, 24];
    if (validMnemonicLengths.contains(wordCount)) {
      if (words.last.isEmpty) {
        return false;
      } else {
        try {
          var tmp = validateMnemonic(mnemonic);
          return tmp;
        } catch (e) {
          return false;
        }
      }
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildConfirmField(),
    ]);
  }
}
