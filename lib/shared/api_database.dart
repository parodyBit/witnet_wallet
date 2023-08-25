import 'dart:isolate';
import 'package:my_wit_wallet/util/account_preferences.dart';
import 'package:my_wit_wallet/util/preferences.dart';
import 'package:witnet/explorer.dart';
import 'package:my_wit_wallet/util/storage/database/database_isolate.dart';
import 'package:my_wit_wallet/util/storage/database/database_service.dart';
import 'package:my_wit_wallet/util/storage/database/wallet.dart';
import 'package:my_wit_wallet/util/storage/path_provider_interface.dart';

import 'package:my_wit_wallet/util/storage/database/account.dart';
import 'package:my_wit_wallet/util/storage/database/wallet_storage.dart';
import 'package:my_wit_wallet/util/storage/database/transaction_adapter.dart';
import 'locator.dart';

class DatabaseException {
  DatabaseException({required this.code, required this.message});
  final int code;
  final String message;
}

enum WalletPreferences { walletId, addressIndex, addressList }

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

  Future<void> updateCurrentWallet(
      {String? currentWalletId,
      bool isHdWallet = false,
      bool isNewWallet = false,
      bool isUpdatedWallet = false}) async {
    ApiDatabase db = Locator.instance<ApiDatabase>();
    WalletStorage walletStorage = db.walletStorage;
    Map<WalletPreferences, dynamic>? preferences =
        await getCurrentWalletPreferences();
    bool currentWalletNotSaved = (isUpdatedWallet || isNewWallet) &&
        currentWalletId != null &&
        preferences != null &&
        preferences[WalletPreferences.addressList][currentWalletId] == null;

    // If localStorage is deleted, it resets preferences of the wallet to default values
    if (currentWalletNotSaved) {
      await setWalletAndAccountInLocalStorage(
          currentWalletId,
          AddressEntry(
              walletId: currentWalletId,
              addressIdx: isHdWallet ? 0 : null,
              keyType: isHdWallet ? '0' : 'm'));
      preferences = await getCurrentWalletPreferences();
    }
    final walletIdToSet =
        preferences != null && !isUpdatedWallet && !isNewWallet
            ? preferences[WalletPreferences.walletId]
            : currentWalletId;

    // set new wallet in storage
    walletStorage.setCurrentWallet(walletIdToSet);

    // get account preferences taking into account corrupted localStorage
    Map<AccountPreferences, dynamic> accountPreferences;
    accountPreferences = getUpdatedAccountInfo(
      AccountPreferencesParams(
        currentWalletId: walletIdToSet,
        preferences: preferences,
        accountList: walletStorage.currentWallet.masterAccount != null
            ? {0: walletStorage.currentWallet.masterAccount!}
            : walletStorage.currentWallet.externalAccounts,
        isHdWallet: walletStorage.currentWallet.masterAccount == null,
      ),
    );

    // set new current wallet and account in local storage
    if (isNewWallet || isUpdatedWallet && currentWalletId != null) {
      await setWalletAndAccountInLocalStorage(
          walletIdToSet,
          AddressEntry(
              walletId: walletIdToSet,
              addressIdx: isHdWallet
                  ? int.tryParse(
                      accountPreferences[AccountPreferences.addressIndex])
                  : null,
              keyType: isHdWallet ? '0' : 'm'));
    }
    // set account in storage
    setCurrentAddressInStorage(
        walletIdToSet,
        accountPreferences[AccountPreferences.address],
        accountPreferences[AccountPreferences.addressList]);
  }

  Future<Map<WalletPreferences, dynamic>?> getCurrentWalletPreferences() async {
    String? walletId = await ApiPreferences.getCurrentWallet();
    String? addressIndex =
        await ApiPreferences.getCurrentAddress(walletId ?? '');
    Map<String, dynamic>? addressList =
        await ApiPreferences.getCurrentAddressList();
    bool hasSavedPrefs = walletId != null &&
        addressIndex != null &&
        addressList != null &&
        addressList.length > 0;
    final prefs = {
      WalletPreferences.walletId: walletId,
      WalletPreferences.addressIndex: addressIndex,
      WalletPreferences.addressList: addressList
    };
    return hasSavedPrefs ? prefs : null;
  }

  Future<void> setWalletAndAccountInLocalStorage(
      walletId, AddressEntry address) async {
    await ApiPreferences.setCurrentWallet(walletId);
    await ApiPreferences.setCurrentAddress(address);
  }

  void setCurrentAddressInStorage(
      walletId, address, Map<String, dynamic> addressList) async {
    walletStorage.setCurrentAccount(address);
    walletStorage.setCurrentAddressList(addressList);
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

  Future<bool> deleteWallet(Wallet wallet) async {
    return await _processIsolate(
        method: 'delete',
        params: {'type': 'wallet', 'value': wallet.jsonMap()});
  }

  Future<bool> deleteAllWallets() async {
    return await _processIsolate(method: 'deleteDatabase');
  }

  Future<bool> addAccount(Account account) async {
    return await _processIsolate(
        method: 'add', params: {'type': 'account', 'value': account.jsonMap()});
  }

  Future<bool> addVtt(ValueTransferInfo transaction) async {
    return await _processIsolate(
        method: 'add', params: {'type': 'vtt', 'value': transaction.jsonMap()});
  }

  Future<bool> addMint(MintEntry transaction) async {
    return await _processIsolate(
        method: 'add',
        params: {'type': 'mint', 'value': transaction.jsonMap()});
  }

  Future<ValueTransferInfo?> getVtt(String hash) async {
    try {
      return await _processIsolate(method: 'getVtt', params: {"hash": hash});
    } catch (err) {
      print('Error getting vtt:: $err');
      return null;
    }
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
    // walletStorage.setAccount(account);
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
