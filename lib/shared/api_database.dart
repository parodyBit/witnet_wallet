import 'dart:isolate';
import 'package:witnet/explorer.dart';
import 'package:my_wit_wallet/util/storage/database/database_isolate.dart';
import 'package:my_wit_wallet/util/storage/database/database_service.dart';
import 'package:my_wit_wallet/util/storage/database/wallet.dart';
import 'package:my_wit_wallet/util/storage/path_provider_interface.dart';

import 'package:my_wit_wallet/util/storage/database/account.dart';
import 'package:my_wit_wallet/util/storage/database/wallet_storage.dart';
import 'locator.dart';

class DatabaseException {
  DatabaseException({required this.code, required this.message});
  final int code;
  final String message;
}

/// [ApiDatabase] is used to communicate between the database isolate and the
/// rest of the application.
class ApiDatabase {
  late String path;
  Map<String, Wallet> _wallets = {};
  bool initialized = false;
  bool unlocked = false;

  late WalletStorage walletStorage;
  bool walletsLoaded = false;

  DatabaseIsolate get databaseIsolate => Locator.instance<DatabaseIsolate>();
  PathProviderInterface interface = PathProviderInterface();

  Future<dynamic> _processIsolate(
      {required String method, Map<String, dynamic>? params}) async {
    if (!databaseIsolate.initialized && !databaseIsolate.loading) {
      await databaseIsolate.init();
    } else {
      do {
        await Future.delayed(Duration(milliseconds: 1));
      } while (databaseIsolate.loading);
      print("databaseIsolate.loading ${databaseIsolate.loading}");
    }
    final ReceivePort response = ReceivePort();
    databaseIsolate.send(
        method: method, params: params ?? {}, port: response.sendPort);
    return await response.first.then((value) {
      if (value.runtimeType == DBException) {
        throw value;
      }
      return value;
    });
  }

  Future<bool> masterKeySet() async {
    try {
      var value = await _processIsolate(
        method: 'masterKeySet',
        params: {},
      );
      return value;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyPassword(String password) async {
    try {
      // verify password if empty but has master key
      ApiDatabase db = Locator.instance<ApiDatabase>();
      String key = await db.getKeychain();
      var value = await _processIsolate(
        method: 'verifyPassword',
        params: {'password': password},
      );
      if (value) {
        unlocked = true;
      }
      return key != '' ? true : value;
    } catch (e) {
      return false;
    }
  }

  Future<String> getKeychain() async {
    try {
      if (unlocked) {
        var value = await _processIsolate(
          method: 'getKeychain',
          params: {},
        );
        // master key
        return value;
      } else {
        throw Exception('Database locked');
      }
    } catch (e) {
      return '';
    }
  }

  Future<bool> setPassword(
      {String? oldPassword, required String newPassword}) async {
    await _processIsolate(
      method: 'setPassword',
      params: {
        'oldPassword': oldPassword ?? '',
        'newPassword': newPassword,
      },
    );
    unlocked = true;
    return true;
  }

  Future<bool> openDatabase() async {
    await interface.init();
    var fileExists = await interface.fileExists(interface.getDbWalletsPath());
    try {
      var response = await _processIsolate(
        method: 'configure',
        params: {
          'path': interface.getDbWalletsPath(),
          'fileExists': fileExists
        },
      );

      assert(response != null);
      return true;
    } on DBException {
      return false;
    }
  }

  Future<bool> lockDatabase() async {
    try {
      var response = await _processIsolate(
        method: 'lock',
        params: {},
      );
      return response;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addWallet(Wallet wallet) async {
    _wallets[wallet.name] = wallet;
    return await _processIsolate(
        method: 'add', params: {'type': 'wallet', 'value': wallet.jsonMap()});
  }

  Future<bool> addAccount(Account account) async {
    return await _processIsolate(
        method: 'add', params: {'type': 'account', 'value': account.jsonMap()});
  }

  Future<bool> addVtt(ValueTransferInfo transaction) async {
    return await _processIsolate(
        method: 'add', params: {'type': 'vtt', 'value': transaction.jsonMap()});
  }

  Future getAllVtts() async {
    try {
      return await _processIsolate(method: 'getAllVtts', params: {});
    } catch (err) {
      print('Error getting vtts:: $err');
    }
  }

  Future<WalletStorage> loadWalletsDatabase() async {
    try {
      /// Get all Wallets
      walletStorage = await _processIsolate(method: 'loadWallets');
      return walletStorage;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateWallet(Wallet wallet) async {
    walletStorage.wallets[wallet.id] = wallet;
    return await _processIsolate(
        method: 'update',
        params: {'type': 'wallet', 'value': wallet.jsonMap()});
  }

  Future<bool> updateVtt(String walletId, ValueTransferInfo vtt) async {
    walletStorage.setVtt(walletId, vtt);

    return await _processIsolate(
        method: 'update', params: {'type': 'vtt', 'value': vtt.jsonMap()});
  }

  Future<bool> deleteVtt(String transactionId) async {
    return await _processIsolate(
        method: 'delete', params: {'value': transactionId});
  }

  Future<bool> updateAccount(Account account) async {
    walletStorage.setAccount(account);
    return await _processIsolate(
        method: 'update',
        params: {'type': 'account', 'value': account.jsonMap()});
  }

  Future<WalletStorage> getWalletStorage([bool reload = false]) async {
    if (reload) {
      walletStorage = await loadWalletsDatabase();
      return walletStorage;
    }
    if (walletsLoaded) {
      return walletStorage;
    } else {
      walletStorage = await loadWalletsDatabase();
      return walletStorage;
    }
  }
}
