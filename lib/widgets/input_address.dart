import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_wit_wallet/widgets/input_text.dart';
import 'package:my_wit_wallet/widgets/styled_text_controller.dart';
import 'package:my_wit_wallet/widgets/suffix_icon_button.dart';
import 'package:my_wit_wallet/widgets/validations/address_input.dart';
import 'package:my_wit_wallet/widgets/validations/validation_utils.dart';
import 'package:my_wit_wallet/widgets/witnet/transactions/value_transfer/create_dialog_box/qr_scanner.dart';

import 'package:my_wit_wallet/theme/extended_theme.dart';
import 'package:my_wit_wallet/util/get_localization.dart';

class InputAddress extends InputText {
  InputAddress(
      {IconData? prefixIcon,
      required FocusNode focusNode,
      String? errorText,
      String? Function(String?)? validator,
      String? hint,
      TextInputType? keyboardType,
      required StyledTextController styledTextController,
      bool obscureText = false,
      this.route,
      void Function(String)? onChanged,
      void Function()? onEditingComplete,
      void Function(String)? onFieldSubmitted,
      void Function(PointerDownEvent)? onTapOutside,
      void Function()? onTap,
      void Function()? onSuffixTap,
      List<TextInputFormatter>? inputFormatters,
      InputDecoration? decoration,
      })
      : super(
          prefixIcon: prefixIcon,
          focusNode: focusNode,
          errorText: errorText,
          validator: validator,
          hint: hint,
          keyboardType: keyboardType,
          styledTextController: styledTextController,
          obscureText: obscureText,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onFieldSubmitted: onFieldSubmitted,
          onTapOutside: onTapOutside,
          onTap: onTap,
          onSuffixTap: onSuffixTap,
          inputFormatters: inputFormatters,
    decoration: decoration,
        );

  final String? route;
  @override
  _InputAddressState createState() => _InputAddressState();
}

class _InputAddressState extends State<InputAddress> {
  AddressInput address = AddressInput.pure();
  FocusNode _scanQrFocusNode = FocusNode();
  bool isScanQrFocused = false;
  ValidationUtils validationUtils = ValidationUtils();

  TextSelection? lastSelection;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _scanQrFocusNode.addListener(_handleQrFocus);
  }

  @override
  void dispose() {
    super.dispose();
    widget.focusNode.removeListener(_onFocusChange);
    _scanQrFocusNode.removeListener(_handleQrFocus);
  }

  void _onFocusChange() {
    TextSelection collapsed = TextSelection.collapsed(
      offset: widget.styledTextController.selection.baseOffset,
      affinity: TextAffinity.upstream,
    );
    if (!widget.focusNode.hasFocus) {
      lastSelection = widget.styledTextController.selection;
      widget.styledTextController.selection = collapsed;
    } else {
      widget.styledTextController.selection = lastSelection ?? collapsed;
    }
  }

  _handleQrFocus() {
    setState(() {
      isScanQrFocused = _scanQrFocusNode.hasFocus;
    });
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extendedTheme = theme.extension<ExtendedTheme>()!;

    widget.styledTextController.setStyle(
      extendedTheme.monoMediumText!.copyWith(color: theme.textTheme.bodyMedium!.color),
      extendedTheme.monoMediumText!.copyWith(color: Colors.black),
    );

    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
          widget.buildInput(context: context, decoration: InputDecoration(
            hintStyle: extendedTheme.monoMediumText,
            hintText: localization.recipientAddress,
            suffixIcon: !Platform.isWindows && !Platform.isLinux
                ? Semantics(
                label: localization.scanQrCodeLabel,
                child: SuffixIcon(
                    onPressed: () => {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => QrScanner(
                              currentRoute: widget.route!,
                              onChanged: (_value) => {})))
                    },
                    icon: FontAwesomeIcons.qrcode,
                    isFocus: isScanQrFocused,
                    focusNode: _scanQrFocusNode))
                : null,
            errorText: widget.errorText,
          )),
        ]);
  }
}
