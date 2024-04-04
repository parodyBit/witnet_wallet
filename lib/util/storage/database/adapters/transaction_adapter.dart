import 'package:witnet/explorer.dart';
import 'package:witnet/schema.dart';

class MintData {
  final List<ValueTransferOutput> outputs;
  final int timestamp;
  final int reward;
  final int valueTransferCount;
  final int dataRequestCount;
  final int commitCount;
  final int revealCount;
  final int tallyCount;

  MintData({
    required this.outputs,
    required this.timestamp,
    required this.reward,
    required this.valueTransferCount,
    required this.dataRequestCount,
    required this.commitCount,
    required this.revealCount,
    required this.tallyCount,
  });
}

class VttData {
  final List<InputUtxo> inputs;
  final List<String> inputAddresses;
  final List<ValueTransferOutput> outputs;
  final List<String> outputAddresses;
  final int weight;
  final int priority;
  final bool confirmed;
  final bool reverted;

  VttData(
      {required this.inputs,
      required this.inputAddresses,
      required this.outputs,
      required this.outputAddresses,
      required this.weight,
      required this.confirmed,
      required this.reverted,
      required this.priority});
}

class GeneralTransaction extends HashInfo {
  MintData? mint;
  VttData? vtt;
  final int fee;
  final int? epoch;

  GeneralTransaction(
      {required blockHash,
      required this.epoch,
      required this.fee,
      required hash,
      required status,
      required time,
      required type,
      this.mint,
      this.vtt})
      : super(
            txnHash: hash,
            status: status,
            type: type,
            txnTime: time,
            blockHash: blockHash);

  factory GeneralTransaction.fromMintEntry(MintEntry mintEntry) =>
      GeneralTransaction(
          blockHash: mintEntry.blockHash,
          epoch: mintEntry.epoch,
          fee: mintEntry.fees,
          hash: mintEntry.blockHash,
          status: mintEntry.status,
          time: mintEntry.timestamp,
          type: mintEntry.type,
          mint: MintData(
              commitCount: mintEntry.commitCount,
              outputs: mintEntry.outputs,
              timestamp: mintEntry.timestamp,
              reward: mintEntry.reward,
              valueTransferCount: mintEntry.valueTransferCount,
              dataRequestCount: mintEntry.dataRequestCount,
              revealCount: mintEntry.revealCount,
              tallyCount: mintEntry.tallyCount),
          vtt: null);
  factory GeneralTransaction.fromValueTransferInfo(
          ValueTransferInfo valueTransferInfo) =>
      GeneralTransaction(
          blockHash: valueTransferInfo.blockHash,
          epoch: valueTransferInfo.epoch,
          fee: valueTransferInfo.fee,
          hash: valueTransferInfo.hash,
          status: valueTransferInfo.status,
          time: valueTransferInfo.timestamp,
          type: valueTransferInfo.type,
          mint: null,
          vtt: VttData(
              inputs: valueTransferInfo.inputUtxos,
              inputAddresses: valueTransferInfo.inputAddresses,
              confirmed: valueTransferInfo.confirmed,
              reverted: valueTransferInfo.reverted,
              outputs: valueTransferInfo.outputs,
              outputAddresses: valueTransferInfo.outputAddresses,
              weight: valueTransferInfo.weight,
              priority: valueTransferInfo.priority));

  ValueTransferInfo toValueTransferInfo() => ValueTransferInfo(
        block: blockHash ??
            '0000000000000000000000000000000000000000000000000000000000000000',
        fee: fee,
        inputUtxos: vtt?.inputs ?? [],
        outputs: vtt?.outputs ?? [],
        priority: vtt?.priority ?? 0,
        status: status,
        epoch: epoch ?? 0,
        hash: txnHash,
        timestamp: txnTime,
        weight: vtt?.weight ?? 0,
        confirmed: vtt?.confirmed ?? false,
        reverted: vtt?.reverted ?? false,
        inputAddresses: vtt?.inputAddresses ?? [],
        outputAddresses: vtt?.outputAddresses ?? [],
        value: 0,
        inputsMerged: [],
        outputValues: [],
        timelocks: List.generate(vtt!.outputs.length,
            (index) => vtt!.outputs[index].timeLock.toInt()),
        utxos: [],
        utxosMerged: [],
        trueOutputAddresses: [],
        changeOutputAddresses: [],
        trueValue: 0,
        changeValue: 0,
      );
}

class MintEntry {
  MintEntry({
    required this.blockHash,
    required this.fees,
    required this.epoch,
    // specific to mint entry
    required this.outputs,
    required this.timestamp,
    required this.reward,
    required this.valueTransferCount,
    required this.dataRequestCount,
    required this.commitCount,
    required this.revealCount,
    required this.tallyCount,
    required this.status,
    required this.type,
    required this.confirmed,
    required this.reverted,
  });
  final String blockHash;
  final List<ValueTransferOutput> outputs;
  final int timestamp;
  final int epoch;
  final int reward;
  final int fees;
  final int valueTransferCount;
  final int dataRequestCount;
  final int commitCount;
  final int revealCount;
  final int tallyCount;
  final TxStatusLabel status;
  final TransactionType type;
  final bool confirmed;
  final bool reverted;

  bool containsAddress(String address) {
    bool response = false;
    outputs.forEach((element) {
      if (element.pkh.address == address) response = true;
    });
    return response;
  }

  Map<String, dynamic> jsonMap() => {
        "block_hash": blockHash,
        "outputs": List<Map<String, dynamic>>.from(
            outputs.map((x) => x.jsonMap(asHex: true))),
        "timestamp": timestamp,
        "epoch": epoch,
        "reward": reward,
        "fees": fees,
        "vtt_count": valueTransferCount,
        "drt_count": dataRequestCount,
        "commit_count": commitCount,
        "reveal_count": revealCount,
        "tally_count": tallyCount,
        'confirmed': confirmed,
        'reverted': reverted,
        "status": status.toString(),
        "type": type.toString(),
      };

  factory MintEntry.fromJson(Map<String, dynamic> json) {
    return MintEntry(
      blockHash: json["block_hash"],
      outputs: List<ValueTransferOutput>.from(
          json["outputs"].map((x) => ValueTransferOutput.fromJson(x))),
      timestamp: json["timestamp"],
      epoch: json["epoch"],
      reward: json["reward"],
      fees: json["fees"],
      valueTransferCount: json["vtt_count"],
      dataRequestCount: json["drt_count"],
      commitCount: json["commit_count"],
      revealCount: json["reveal_count"],
      tallyCount: json["tally_count"],
      confirmed: json['confirmed'] ?? false,
      reverted: json['reverted'] ?? false,
      status: TransactionStatus.fromJson(json).status,
      type: TransactionType.mint,
    );
  }

  factory MintEntry.fromBlockMintInfo(
          BlockInfo blockInfo, BlockDetails blockDetails) =>
      MintEntry(
        blockHash: blockDetails.mintInfo.blockHash,
        outputs: blockDetails.mintInfo.outputs,
        timestamp: blockInfo.timestamp,
        epoch: blockInfo.epoch,
        reward: blockInfo.reward,
        fees: blockInfo.fees,
        valueTransferCount: blockInfo.valueTransferCount,
        dataRequestCount: blockInfo.dataRequestCount,
        commitCount: blockInfo.commitCount,
        revealCount: blockInfo.revealCount,
        tallyCount: blockInfo.tallyCount,
        status: TransactionStatus.fromJson({
          'confirmed': blockDetails.confirmed,
          'reverted': blockDetails.reverted
        }).status,
        type: TransactionType.mint,
        confirmed: blockDetails.confirmed,
        reverted: blockDetails.reverted,
      );
}

extension InputUtxoAdapter on InputUtxo {
  static InputUtxo fromDBJson(Map<String, dynamic> json) => InputUtxo(
      address: json["pkh"],
      inputUtxo: json["output_pointer"],
      value: json["value"]);

  static InputUtxo fromJson(Map<String, dynamic> json) {
    bool dbJson = json["pkh"] != null;
    if (dbJson) {
      return fromDBJson(json);
    } else {
      return InputUtxo.fromJson(json);
    }
  }
}

// TODO: it is not used, delete if not necessary
extension AddressBlocksAdapter on AddressBlocks {
  static AddressBlocks fromDBJson(List<dynamic> data) {
    return AddressBlocks(
      address: data[0]['address'],
      blocks: List<BlockInfo>.from(
          data.map((blockInfo) => BlockInfo.fromJson(blockInfo))),
    );
  }

  static AddressBlocks fromJson(List<dynamic> data) {
    bool dbJson = data[0]['miner'] == null;
    if (dbJson) {
      return fromDBJson(data);
    } else {
      return AddressBlocks.fromJson(data);
    }
  }
}

extension ValueTransferAdapter on ValueTransferInfo {
  static ValueTransferInfo fromJson(Map<String, dynamic> data) {
    bool dbJson = data["epoch"] == null;
    if (dbJson) {
      return fromDBJson(data);
    } else {
      return ValueTransferInfo.fromJson(data);
    }
  }

  static ValueTransferInfo fromDBJson(Map<String, dynamic> data) {
    List<String> outputAddresses = getOrDefault(data).outputAddresses;
    List<int> outputValues = getOrDefault(data).outputValues;
    List<ValueTransferOutput> outputs = [];
    if (data['outputs'] != null) {
      data['outputs'].forEach((element) {
        Address address = Address.fromAddress(element['pkh']);

        outputs.add(ValueTransferOutput(
            pkh: address.publicKeyHash!,
            timeLock: element['time_lock'],
            value: element['value']));
      });
    } else {
      for (int i = 0; i < outputValues.length; i++) {
        ValueTransferOutput vto = ValueTransferOutput(
          value: outputValues[i],
          pkh: Address.fromAddress(outputAddresses[i]).publicKeyHash!,
          timeLock: getOrDefault(data).timelocks[i],
        );
        outputs.add(vto);
      }
    }
    return ValueTransferInfo(
        epoch: data["txn_epoch"],
        timestamp: data["txn_time"],
        hash: data["txn_hash"],
        block: data["block_hash"],
        inputUtxos: List<InputUtxo>.from(
            data["inputs"].map((x) => InputUtxoAdapter.fromJson(x))),
        fee: data["fee"],
        priority: data["priority"],
        weight: data["weight"],
        status: TransactionStatus.fromJson(data).status,
        outputs: outputs,
        value: getOrDefault(data).value,
        confirmed: getOrDefault(data).confirmed,
        reverted: getOrDefault(data).reverted,
        inputAddresses: getOrDefault(data).inputAddresses,
        inputsMerged: getOrDefault(data).inputsMerged,
        outputAddresses: getOrDefault(data).outputAddresses,
        outputValues: getOrDefault(data).outputValues,
        timelocks: getOrDefault(data).timelocks,
        utxos: getOrDefault(data).utxos,
        utxosMerged: getOrDefault(data).utxosMerged,
        trueOutputAddresses: getOrDefault(data).trueOutputAddresses,
        changeOutputAddresses: getOrDefault(data).outputAddresses,
        trueValue: getOrDefault(data).trueValue,
        changeValue: getOrDefault(data).changeValue);
  }
}

class NullableFields {
  final int? value;
  final bool confirmed;
  final bool reverted;
  final List<String> inputAddresses;
  final List<InputMerged> inputsMerged;
  final List<String> outputAddresses;
  final List<int> outputValues;
  final List<int> timelocks;
  final List<TransactionUtxo> utxos;
  final List<TransactionUtxo> utxosMerged;
  final List<String> trueOutputAddresses;
  final List<String> changeOutputAddresses;
  final int? trueValue;
  final int? changeValue;
  NullableFields(
      {required this.changeOutputAddresses,
      required this.changeValue,
      required this.confirmed,
      required this.inputAddresses,
      required this.inputsMerged,
      required this.outputAddresses,
      required this.outputValues,
      required this.reverted,
      required this.timelocks,
      required this.trueOutputAddresses,
      required this.trueValue,
      required this.utxos,
      required this.utxosMerged,
      required this.value});
}

NullableFields getOrDefault(Map<String, dynamic> data) {
  return NullableFields(
    value: data["value"] ?? null,
    confirmed: data["confirmed"] ??
        TransactionStatus.fromJson(data).status == TxStatusLabel.confirmed,
    reverted: data["reverted"] ??
        TransactionStatus.fromJson(data).status == TxStatusLabel.reverted,
    inputAddresses: data["input_addresses"] != null
        ? List<String>.from(data["input_addresses"])
        : List<String>.from(data["inputs"].map((input) {
            return input['pkh'];
          }).toList()),
    inputsMerged: data["inputs_merged"] != null
        ? List<InputMerged>.from(
            data["inputs_merged"].map((x) => InputMerged.fromJson(x)))
        : [],
    outputAddresses: data["output_addresses"] != null
        ? List<String>.from(data["output_addresses"])
        : List<String>.from(
            data["outputs"].map((output) => output['pkh']).toList()),
    outputValues: data["output_values"] != null
        ? List<int>.from(data["output_values"])
        : List<int>.from(
            data["outputs"].map((output) => output['value']).toList()),
    timelocks: data["timelocks"] != null
        ? List<int>.from(data["timelocks"])
        : List<int>.from(
            data["outputs"].map((output) => output['time_lock']).toList()),
    utxos: data["utxos"] != null
        ? List<TransactionUtxo>.from(data["utxos"]
            .map((e) => TransactionUtxo.fromJson(Map<String, dynamic>.from(e))))
        : [],
    utxosMerged: data["utxos_merged"] != null
        ? List<TransactionUtxo>.from(data["utxos_merged"]
            .map((e) => TransactionUtxo.fromJson(Map<String, dynamic>.from(e))))
        : [],
    trueOutputAddresses: data["true_output_addresses"] != null
        ? List<String>.from(data["true_output_addresses"])
        : [],
    changeOutputAddresses: data["change_output_addresses"] != null
        ? List<String>.from(data["change_output_addresses"])
        : [],
    trueValue: data["true_value"],
    changeValue: data["change_value"],
  );
}
