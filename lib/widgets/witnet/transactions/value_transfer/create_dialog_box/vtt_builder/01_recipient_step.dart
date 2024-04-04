import 'package:formz/formz.dart';
import 'package:intl/intl.dart';
import 'package:my_wit_wallet/constants.dart';
import 'package:my_wit_wallet/screens/send_transaction/send_vtt_screen.dart';
import 'package:my_wit_wallet/theme/colors.dart';
import 'package:my_wit_wallet/util/extensions/num_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_wit_wallet/util/showTxConnectionError.dart';
import 'package:my_wit_wallet/widgets/suffix_icon_button.dart';
import 'package:my_wit_wallet/widgets/snack_bars.dart';
import 'package:my_wit_wallet/widgets/validations/address_input.dart';
import 'package:my_wit_wallet/widgets/validations/validation_utils.dart';
import 'package:my_wit_wallet/widgets/validations/vtt_amount_input.dart';
import 'package:my_wit_wallet/widgets/witnet/transactions/value_transfer/create_dialog_box/vtt_builder/timelock_picker.dart';
import 'package:witnet/schema.dart';
import 'package:my_wit_wallet/bloc/transactions/value_transfer/vtt_create/vtt_create_bloc.dart';
import 'package:my_wit_wallet/screens/create_wallet/nav_action.dart';
import 'package:my_wit_wallet/util/storage/database/balance_info.dart';
import 'package:my_wit_wallet/util/storage/database/wallet.dart';
import 'package:my_wit_wallet/widgets/input_amount.dart';
import 'package:my_wit_wallet/util/extensions/text_input_formatter.dart';
import 'dart:io' show Platform;
import 'package:my_wit_wallet/util/get_localization.dart';
import 'package:my_wit_wallet/widgets/witnet/transactions/value_transfer/create_dialog_box/qr_scanner.dart';
import 'package:my_wit_wallet/theme/extended_theme.dart';

class RecipientStep extends StatefulWidget {
  final Function nextAction;
  final Wallet currentWallet;
  final VoidCallback goNext;

  RecipientStep({
    required Key? key,
    required this.currentWallet,
    required this.nextAction,
    required this.goNext,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => RecipientStepState();
}

class RecipientStepState extends State<RecipientStep>
    with SingleTickerProviderStateMixin {
  late BalanceInfo balanceInfo = widget.currentWallet.balanceNanoWit();
  late AnimationController _loadingController;
  final _formKey = GlobalKey<FormState>();
  AddressInput _address = AddressInput.pure();
  VttAmountInput _amount = VttAmountInput.pure();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _addressController = TextEditingController();
  final _addressFocusNode = FocusNode();
  bool _connectionError = false;
  FocusNode _scanQrFocusNode = FocusNode();
  bool isScanQrFocused = false;
  ValidationUtils validationUtils = ValidationUtils();
  List<FocusNode> _formFocusElements() => [_addressFocusNode, _amountFocusNode];
  ValueTransferOutput? ongoingOutput;
  VTTCreateBloc get vttBloc => BlocProvider.of<VTTCreateBloc>(context);

  bool showAdvancedSettings = false;
  bool timelockSet = false;
  int _currIndex = 0;
  DateTime currentTime = DateTime.now();
  DateTime? timelockValue;
  DateTime? calendarValue;
  @override
  void initState() {
    super.initState();
    if (vttBloc.outputs.length > 0) {
      ongoingOutput = vttBloc.outputs.first;
      _setSavedTxData(ongoingOutput);
    }
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scanQrFocusNode.addListener(_handleFocus);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.nextAction(next),
    );
  }

  @override
  void dispose() {
    _scanQrFocusNode.removeListener(_handleFocus);
    _loadingController.dispose();
    _addressController.dispose();
    _addressFocusNode.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  _handleFocus() {
    setState(() {
      isScanQrFocused = _scanQrFocusNode.hasFocus;
    });
  }

  num _amountToNumber() {
    try {
      return num.parse((_amount.value) != '' ? _amount.value : '0');
    } catch (e) {
      return 0;
    }
  }

  bool formValidation() {
    final validInputs = <FormzInput>[
      _amount,
      _address,
    ];
    return Formz.validate(validInputs);
  }

  bool validateForm({force = false}) {
    if (force) {
      setAddress(_address.value, validate: true);
      setAmount(_amount.value, validate: true);
    }
    return formValidation() && !_connectionError;
  }

  void setAddress(String value, {bool? validate}) {
    setState(() {
      _address = AddressInput.dirty(
          value: value,
          allowValidation:
              validate ?? validationUtils.isFormUnFocus(_formFocusElements()));
    });
  }

  void setAmount(String value, {bool? validate}) {
    setState(() {
      _amount = VttAmountInput.dirty(
          availableNanoWit: balanceInfo.availableNanoWit,
          allowValidation:
              validate ?? validationUtils.isFormUnFocus(_formFocusElements()),
          value: value);
    });
  }

  void _setSavedTxData(ValueTransferOutput? ongoingOutput) {
    String? savedAddress = ongoingOutput?.pkh.address;
    String? savedAmount =
        ongoingOutput?.value.toInt().standardizeWitUnits().toString();

    if (savedAddress != null) {
      _addressController.text = savedAddress;
      setAddress(savedAddress, validate: false);
    }

    if (savedAmount != null) {
      _amountController.text = savedAmount;
      setAmount(savedAmount, validate: false);
    }

    vttBloc.add(ResetTransactionEvent());
  }

  void nextAction() {
    final theme = Theme.of(context);
    if (_connectionError) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(buildErrorSnackbar(
          theme, localization.connectionIssue, theme.colorScheme.error));
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    if (validateForm(force: true)) {
      vttBloc.add(AddValueTransferOutputEvent(
          currentWallet: widget.currentWallet,
          output: ValueTransferOutput.fromJson({
            'pkh': _address.value,
            'value': int.parse(_amountToNumber()
                .standardizeWitUnits(
                    inputUnit: WitUnit.Wit, outputUnit: WitUnit.nanoWit)
                .toString()),
            'time_lock': timelockSet ? dateTimeToTimelock(calendarValue) : 0,
          }),
          merge: true));
    }
  }

  NavAction next() {
    return NavAction(
      label: localization.continueLabel,
      action: nextAction,
    );
  }

  void _setTimeLock() async {
    final DateTime? value = await showTimelockPicker(context: context);
    if (value == null) {
      setState(() {
        calendarValue = null;
        timelockSet = false;
      });
    } else {
      setState(() {
        calendarValue = value;
        timelockSet = true;
        _currIndex = _currIndex == 0 ? 1 : 0;
      });
    }
  }

  void _clearTimeLock() async {
    setState(() {
      calendarValue = null;
      timelockSet = false;
      _currIndex = _currIndex == 0 ? 1 : 0;
    });
  }

  String _formatTimeLock() =>
      DateFormat('h:mm a E, MMM dd yyyy ').format(calendarValue!);

  _buildCalendarDialogButton(BuildContext context) {
    final theme = Theme.of(context);
    ExtendedTheme extendedTheme = theme.extension<ExtendedTheme>()!;
    Column timelockWidget = Column(
      children: [
        SizedBox(height: 15),
        Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(localization.timelock, style: theme.textTheme.titleSmall),
              SizedBox(width: 8),
              Tooltip(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.background,
                  ),
                  textStyle: theme.textTheme.bodyMedium,
                  height: 60,
                  message: localization.timelockTooltip,
                  child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(FontAwesomeIcons.circleQuestion,
                          size: 12, color: extendedTheme.inputIconColor)))
            ]),
        SizedBox(
          height: 8,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _setTimeLock,
              child: Row(
                children: [
                  Text(
                      '${timelockSet ? _formatTimeLock() : localization.setTimelock}'),
                  timelockSet ? Container() : SizedBox(width: 10),
                  timelockSet
                      ? Container()
                      : Icon(FontAwesomeIcons.calendar, size: 14),
                ],
              ),
            ),
            timelockSet
                ? IconButton(
                    onPressed: () =>
                        timelockSet ? _clearTimeLock() : _setTimeLock(),
                    icon: Icon(
                      FontAwesomeIcons.trashCan,
                      color: Colors.red,
                    ))
                : Container()
          ],
        ),
      ],
    );

    return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      showAdvancedSettings = !showAdvancedSettings;
                    });
                  },
                  child: Row(
                    children: [
                      Text("Advanced Settings"),
                      SizedBox(width: 10),
                      Icon(
                        showAdvancedSettings
                            ? FontAwesomeIcons.caretDown
                            : FontAwesomeIcons.caretUp,
                        color: WitnetPallet.witnetGreen1,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            showAdvancedSettings ? timelockWidget : Container()
          ],
        ));
  }

  _buildForm(BuildContext context, ThemeData theme) {
    final theme = Theme.of(context);
    _addressFocusNode.addListener(() => validateForm());
    _amountFocusNode.addListener(() => validateForm());
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Padding(
          padding: EdgeInsets.only(left: 8, right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localization.address,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: 8),
              TextFormField(
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: localization.recipientAddress,
                  suffixIcon: !Platform.isWindows && !Platform.isLinux
                      ? SuffixIcon(
                          onPressed: () => {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => QrScanner(
                                            currentRoute: CreateVttScreen.route,
                                            onChanged: (String value) => {
                                                  Navigator.popUntil(
                                                      context,
                                                      ModalRoute.withName(
                                                          CreateVttScreen
                                                              .route)),
                                                  _addressController.text =
                                                      value,
                                                  setAddress(value)
                                                })))
                              },
                          icon: FontAwesomeIcons.qrcode,
                          isFocus: isScanQrFocused,
                          focusNode: _scanQrFocusNode)
                      : null,
                  errorText: _address.error,
                ),
                controller: _addressController,
                focusNode: _addressFocusNode,
                keyboardType: TextInputType.text,
                inputFormatters: [WitAddressFormatter()],
                onChanged: (String value) {
                  setAddress(value);
                },
                onFieldSubmitted: (String value) {
                  _amountFocusNode.requestFocus();
                },
                onTap: () {
                  _addressFocusNode.requestFocus();
                },
              ),
              SizedBox(height: 16),
              Text(
                localization.amount,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: 8),
              InputAmount(
                hint: localization.amount,
                errorText: _amount.error,
                textEditingController: _amountController,
                focusNode: _amountFocusNode,
                keyboardType: TextInputType.number,
                onChanged: (String value) {
                  setAmount(value);
                },
                onTap: () {
                  _amountFocusNode.requestFocus();
                },
                onFieldSubmitted: (String value) {
                  // hide keyboard
                  FocusManager.instance.primaryFocus?.unfocus();
                  widget.goNext();
                },
              ),
              _buildCalendarDialogButton(context),
              SizedBox(height: 16),
            ],
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<VTTCreateBloc, VTTCreateState>(
      listenWhen: (previousState, currentState) {
        if (showTxConnectionReEstablish(
            previousState.vttCreateStatus, currentState.vttCreateStatus)) {
          setState(() {
            _connectionError = false;
          });
        }
        return true;
      },
      listener: (context, state) {
        if (state.vttCreateStatus == VTTCreateStatus.exception) {
          setState(() {
            _connectionError = true;
          });
        }
      },
      child: _buildForm(context, theme),
    );
  }
}
