import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:witnet/utils.dart';
import 'package:witnet/witnet.dart';
import 'package:witnet_wallet/bloc/auth/create_wallet/api_create_wallet.dart';
import 'package:witnet_wallet/screens/create_wallet/import_xprv/import_xprv_bloc.dart';
import 'package:witnet_wallet/shared/locator.dart';

class EnterXprvCard extends StatefulWidget {
  EnterXprvCard({Key? key}) : super(key: key);

  EnterXprvCardState createState() => EnterXprvCardState();
}

class EnterXprvCardState extends State<EnterXprvCard>
    with TickerProviderStateMixin {
  String xprv = '';
  final TextEditingController textController = TextEditingController();
  int numLines = 0;
  bool _xprvVerified = false;
  bool xprvVerified() => _xprvVerified;
  Widget _buildConfirmField() {
    return SizedBox(
      child: Padding(
        padding: EdgeInsets.all(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 10,
            ),
            TextField(
              keyboardType: TextInputType.multiline,
              maxLines: 4,
              controller: textController,
              onChanged: (String e) {
                setState(() {
                  print(e);
                  xprv = textController.value.text;
                  numLines = '\n'.allMatches(e).length + 1;
                });
              },
              decoration: new InputDecoration(
                  labelText: 'XPRV',
                  border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(10.0))),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  void onBack() {
    BlocProvider.of<BlocImportXprv>(context)
        .add(SetStateEvent(EnterXprvState()));
    BlocProvider.of<BlocImportXprv>(context).add(PreviousCardEvent());
  }

  void onNext() {
    Locator.instance<ApiCreateWallet>().setSeed(xprv, 'xprv');
    BlocProvider.of<BlocImportXprv>(context).add(NextCardEvent());
  }

  bool validBech(String xprvString) {
    try {
      Bech32 bech = bech32.decode(xprvString);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  bool validXprv(String xprvString) {
    try {
      Xprv _xprv = Xprv.fromXprv(xprvString);
      print(_xprv.address.address);
    } catch (e) {
      return false;
    }
    return true;
  }

  Widget _buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: ElevatedButton(
            onPressed: onBack,
            child: Text('Go back!'),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 5, top: 10, bottom: 10),
          child: ElevatedButton(
            onPressed: xprvVerified() ? onNext : null,
            child: Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Widget buildErrorList(List<dynamic> errors) {
    List<Widget> _children = [];
    errors.forEach((element) {
      _children.add(Text(
        element.toString(),
        style: TextStyle(color: Colors.red),
      ));
    });
    return Column(children: _children);
  }

  Widget _verifyButton() {
    return ElevatedButton(
      onPressed: () {
        BlocProvider.of<BlocImportXprv>(context).add(VerifyXprvEvent(xprv));
        try {
          print('Valid bech? ${validBech(xprv)}');
          print('Valid xprv? ${validXprv(xprv)}');
          Xprv _xprv = Xprv.fromXprv(xprv);
          setState(() {
            _xprvVerified = validXprv(xprv);
          });
        } catch (e) {}
      },
      child: Text('Verify'),
    );
  }

  Widget verifyXprvButton() {
    return BlocBuilder<BlocImportXprv, ImportXprvState>(
        builder: (context, state) {
      final theme = Theme.of(context);
      if (state is EnterXprvState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _verifyButton(),
          ],
        );
      } else if (state is LoadingState) {
        return SpinKitCircle(
          color: theme.primaryColor,
        );
      } else if (state is ValidXprvState) {
        return Container(
          child: Column(
            children: [
              Text('Verify the imported addresses match your records.'),
              Text('Master Node address: ${state.nodeAddress}'),
              Text('First Wallet address: ${state.walletAddress}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _verifyButton(),
                ],
              )
            ],
          ),
        );
      } else if (state is LoadingErrorState) {
        return Container(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildErrorList(state.errors),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _verifyButton(),
                ],
              )
            ],
          ),
        );
      } else {
        return SpinKitCircle(
          color: theme.primaryColor,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;

    final cardWidth = min(deviceSize.width * 0.95, 360.0);
    const cardPadding = 10.0;
    final textFieldWidth = cardWidth - cardPadding * 2;
    final theme = Theme.of(context);
    return FittedBox(
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 50,
              width: cardWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5.0),
                      topRight: Radius.circular(5.0))),
              child: Padding(
                padding: EdgeInsets.only(top: 1),
                child: Text(
                  'Import XPRV',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.backgroundColor, fontSize: 25),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: cardPadding,
                right: cardPadding,
                top: cardPadding + 10,
              ),
              width: cardWidth,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _buildConfirmField(),
                    verifyXprvButton(),
                    _buildButtonRow(),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
