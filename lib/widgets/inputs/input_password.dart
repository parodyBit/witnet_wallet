import 'package:flutter/material.dart';
import 'package:my_wit_wallet/util/get_localization.dart';
import 'package:my_wit_wallet/widgets/inputs/input_text.dart';
import 'package:my_wit_wallet/widgets/suffix_icon_button.dart';

class InputPassword extends InputText {
  InputPassword({
    required this.showPassFocusNode,
    super.prefixIcon,
    required super.focusNode,
    super.errorText,
    super.validator,
    super.hint,
    super.keyboardType,
    required super.styledTextController,
    super.obscureText = false,
    super.onChanged,
    super.onEditingComplete,
    super.onFieldSubmitted,
    super.onTapOutside,
    super.onTap,
    super.onSuffixTap,
    super.inputFormatters,
    maxLines = 1,
  });

  final FocusNode? showPassFocusNode;
  @override
  _InputLoginState createState() => _InputLoginState();
}

class _InputLoginState extends State<InputPassword> {
  bool showPassword = false;
  bool showPasswordFocus = false;

  void initState() {
    super.initState();
    widget.styledTextController.obscureText = !showPassword;
    widget.focusNode.addListener(widget.onFocusChange);
    if (widget.showPassFocusNode != null && this.mounted)
      widget.showPassFocusNode!.addListener(widget.onFocusChange);
  }

  void dispose() {
    super.dispose();
    widget.focusNode.removeListener(widget.onFocusChange);
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    widget.styledTextController.setStyle(
      theme.textTheme.bodyLarge!,
      theme.textTheme.bodyLarge!.copyWith(color: Colors.black),
    );
    return Container(
        child: Semantics(
      textField: true,
      label: localization.inputYourPassword,
      child: widget.buildInput(
        context: context,
        decoration: InputDecoration(
            suffixIconConstraints: BoxConstraints(minWidth: 50),
            hintText: widget.hint ?? localization.inputYourPassword,
            errorText: widget.errorText,
            prefixIcon:
                widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: Semantics(
              label: localization.showPassword,
              child: SuffixIcon(
                  iconSize: theme.iconTheme.size,
                  icon: showPassword
                      ? Icons.remove_red_eye
                      : Icons.visibility_off,
                  focusNode: widget.showPassFocusNode ?? FocusNode(),
                  onPressed: () {
                    setState(() => showPassword = !showPassword);
                    widget.styledTextController.obscureText = !showPassword;
                  },
                  isFocus: (widget.showPassFocusNode != null &&
                      widget.showPassFocusNode!.hasFocus)),
            )),
      ),
    ));
  }
}
