import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';

class PayClient {
  PayClient() {
    print('Setting up revenue cat');
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    Purchases.setDebugLogsEnabled(true);
    await Purchases.setup("QeLxiJjDOiuquzQjgonjkslTqPSyGkSg");
  }

  getOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current.availablePackages.isNotEmpty) {
        // Display packages for sale
        print(offerings);
        print(offerings.current.availablePackages);
        return offerings;
      }
    } on PlatformException catch (e) {
      // optional error handling
      print(e);
    }
  }

  getSubscriptionStatus() async {
    try {
      PurchaserInfo purchaserInfo = await Purchases.getPurchaserInfo();
      // print(purchaserInfo.entitlements.all);
      bool subIsActive =
          purchaserInfo.entitlements.all["FunkymunchSubscription"].isActive;
      if (subIsActive) {
        // Grant user "pro" access
        return true;
      }
    } on PlatformException catch (e) {
      // Error fetching purchaser info
      print(e);
    }
    return false;
  }

  makePurchase(package) async {
    try {
      PurchaserInfo purchaserInfo = await Purchases.purchasePackage(package);
      if (purchaserInfo.entitlements.all["FunkymunchSubscription"].isActive) {
        // Unlock that great "pro" content
        print(purchaserInfo);
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print(e);
      }
    }
  }
}
