import 'package:my_wit_wallet/shared/api_database.dart';
import 'package:my_wit_wallet/util/storage/database/account.dart';

enum AccountPreferences { address, addressIndex, addressList }

class AccountPreferencesParams {
  String? currentWalletId;
  Map<WalletPreferences, dynamic>? preferences;
  Map<int, Account> externalAccounts;
  AccountPreferencesParams(
      this.currentWalletId, this.preferences, this.externalAccounts);
}

Map<AccountPreferences, dynamic> getUpdatedAccountInfo(
    AccountPreferencesParams params) {
  bool isHdWallet = params.externalAccounts.isNotEmpty;
  String addressId = isHdWallet ? "0/0" : "m";
  Map<String, dynamic> addressList = {
    '${params.currentWalletId}': isHdWallet ? "0/0" : "m"
  };
  if (params.preferences != null) {
    addressList = params.preferences![WalletPreferences.addressList];
    addressId = params.currentWalletId != null
        ? addressList[params.currentWalletId]
        : params.preferences![WalletPreferences.addressIndex];
  }
  int addressIndex =
      addressId.contains("/") ? int.parse(addressId.split('/').last) : 0;

  bool isAddressIdxInStorage = params.externalAccounts.length > 0 &&
      (addressIndex < params.externalAccounts.length);
  Map<String, dynamic> defaultAccountSettings = {
    ...addressList,
    '${params.currentWalletId}': isHdWallet ? "0/0" : "m",
  };
  String? defaultAddress = params.externalAccounts[0] != null
      ? params.externalAccounts[0]!.address
      : null;
  return {
    AccountPreferences.address: isAddressIdxInStorage
        ? params.externalAccounts[addressIndex]!.address
        : defaultAddress,
    AccountPreferences.addressIndex:
        isAddressIdxInStorage ? addressIndex.toString() : "0",
    AccountPreferences.addressList:
        isAddressIdxInStorage ? addressList : defaultAccountSettings,
  };
}
