import 'package:budget/struct/settings.dart';
import 'dart:convert';
import 'package:budget/database/tables.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic> currenciesJSON = {};

loadCurrencyJSON() async {
  currenciesJSON = await json.decode(
      await rootBundle.loadString('assets/static/generated/currencies.json'));
}

Future<bool> getExchangeRates() async {
  print("Getting exchange rates for current wallets");
  // List<String?> uniqueCurrencies =
  //     await database.getUniqueCurrenciesFromWallets();
  Map<dynamic, dynamic> cachedCurrencyExchange =
      appStateSettings["cachedCurrencyExchange"];
  try {
    Uri url = Uri.parse(
        "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json");
    dynamic response = await http.get(url);
    if (response.statusCode == 200) {
      cachedCurrencyExchange = json.decode(response.body)?["usd"];
    }
  } catch (e) {
    print("Error getting currency rates: " + e.toString());
    return false;
  }
  // Gold rate is fetched independently and inserted into the same map
  Map<String, dynamic> goldResult = await fetchGoldRate();
  if (goldResult["ok"] == true) {
    double usdPerLuong = goldResult["usdPerLuong"];
    cachedCurrencyExchange["luongvang"] = 1 / usdPerLuong;
  }
  // print(cachedCurrencyExchange);
  updateSettings(
    "cachedCurrencyExchange",
    cachedCurrencyExchange,
    updateGlobalState:
        appStateSettings["cachedCurrencyExchange"].keys.length <= 0,
  );
  return true;
}

/// Fetches the current VND-per-luong gold price from vang.today and converts
/// it into a USD-based rate suitable for the existing exchange rate map.
///
/// Returns a result map:
///   - ok=true,  buyVndPerLuong, usdPerLuong, stored
///   - ok=false, error (String describing why)
/// Caller decides whether to write into the cached exchange map.
Future<Map<String, dynamic>> fetchGoldRate() async {
  try {
    Uri url = Uri.parse("https://vang.today/api/prices?type=BT9999NTT");
    print("[gold] GET $url");
    dynamic response = await http.get(url);
    print("[gold] status=${response.statusCode}");
    if (response.statusCode != 200) {
      String err = "HTTP ${response.statusCode}";
      print("[gold] error: $err");
      return {"ok": false, "error": err};
    }
    dynamic body = json.decode(response.body);
    print("[gold] body=$body");
    if (body is! Map || body["success"] != true) {
      return {"ok": false, "error": "Invalid body shape"};
    }
    dynamic buy = body["buy"];
    if (buy is! num || buy <= 0) {
      return {"ok": false, "error": "Missing/invalid buy price"};
    }
    double buyVndPerLuong = buy.toDouble();
    Map<dynamic, dynamic> cached = appStateSettings["cachedCurrencyExchange"];
    dynamic vndPerUsd = cached is Map ? cached["vnd"] : null;
    if (vndPerUsd is! num || vndPerUsd <= 0) {
      // Fetch VND rate independently so we don't depend on the earlier API call
      try {
        Uri vndUrl = Uri.parse(
            "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/vnd.min.json");
        dynamic r = await http.get(vndUrl);
        if (r.statusCode == 200) {
          // 1 VND = X USD  =>  vndPerUsd = 1 / X
          dynamic vndToUsd = json.decode(r.body)?["vnd"]?["usd"];
          if (vndToUsd is num && vndToUsd > 0) {
            vndPerUsd = 1 / vndToUsd.toDouble();
          }
        }
      } catch (e) {
        print("[gold] vnd fallback fetch error: $e");
      }
      if (vndPerUsd is! num || vndPerUsd <= 0) {
        String err = "VND rate unavailable";
        print("[gold] error: $err");
        return {"ok": false, "error": err, "buyVndPerLuong": buyVndPerLuong};
      }
    }
    double usdPerLuong = buyVndPerLuong / vndPerUsd.toDouble();
    double stored = 1 / usdPerLuong;
    print("[gold] buyVndPerLuong=$buyVndPerLuong vndPerUsd=$vndPerUsd usdPerLuong=$usdPerLuong stored=$stored");
    Map<String, dynamic> goldInfo = {
      "buyVndPerLuong": buyVndPerLuong,
      "fetchedAt": DateTime.now().toIso8601String(),
      "source": "vang.today?type=BT9999NTT",
    };
    updateSettings("goldRateInfo", goldInfo, updateGlobalState: false);
    return {
      "ok": true,
      "buyVndPerLuong": buyVndPerLuong,
      "usdPerLuong": usdPerLuong,
      "stored": stored,
    };
  } catch (e) {
    print("[gold] exception: $e");
    return {"ok": false, "error": e.toString()};
  }
}

double amountRatioToPrimaryCurrencyGivenPk(
  AllWallets allWallets,
  String walletPk, {
  Map<String, dynamic>? appStateSettingsPassed,
}) {
  if (allWallets.indexedByPk[walletPk] == null) return 1;
  return amountRatioToPrimaryCurrency(
    allWallets,
    allWallets.indexedByPk[walletPk]?.currency,
    appStateSettingsPassed: appStateSettingsPassed,
  );
}

double amountRatioToPrimaryCurrency(
  AllWallets allWallets,
  String? walletCurrency, {
  Map<String, dynamic>? appStateSettingsPassed,
}) {
  if (walletCurrency == null) {
    return 1;
  }
  if (allWallets
          .indexedByPk[
              (appStateSettingsPassed ?? appStateSettings)["selectedWalletPk"]]
          ?.currency ==
      walletCurrency) {
    return 1;
  }
  if (allWallets.indexedByPk[
          (appStateSettingsPassed ?? appStateSettings)["selectedWalletPk"]] ==
      null) {
    return 1;
  }

  double exchangeRateFromUSDToTarget = getCurrencyExchangeRate(
    allWallets
        .indexedByPk[
            (appStateSettingsPassed ?? appStateSettings)["selectedWalletPk"]]
        ?.currency,
    appStateSettingsPassed: appStateSettingsPassed,
  );
  double exchangeRateFromCurrentToUSD = 1 /
      getCurrencyExchangeRate(
        walletCurrency,
        appStateSettingsPassed: appStateSettingsPassed,
      );
  return exchangeRateFromUSDToTarget * exchangeRateFromCurrentToUSD;
}

double? amountRatioFromToCurrency(
    String walletCurrencyBefore, String walletCurrencyAfter) {
  double exchangeRateFromUSDToTarget =
      getCurrencyExchangeRate(walletCurrencyAfter);
  double exchangeRateFromCurrentToUSD =
      1 / getCurrencyExchangeRate(walletCurrencyBefore);
  return exchangeRateFromUSDToTarget * exchangeRateFromCurrentToUSD;
}

// assume selected wallets currency
String getCurrencyString(AllWallets allWallets, {String? currencyKey}) {
  String? selectedWalletCurrency =
      allWallets.indexedByPk[appStateSettings["selectedWalletPk"]]?.currency;
  return currencyKey != null
      ? (currenciesJSON[currencyKey]?["Symbol"] ?? "")
      : selectedWalletCurrency == null
          ? ""
          : (currenciesJSON[selectedWalletCurrency]?["Symbol"] ?? "");
}

double getCurrencyExchangeRate(
  String? currencyKey, {
  Map<String, dynamic>? appStateSettingsPassed,
}) {
  if (currencyKey == null || currencyKey == "") return 1;
  if ((appStateSettingsPassed ?? appStateSettings)["customCurrencyAmounts"]
          ?[currencyKey] !=
      null) {
    return (appStateSettingsPassed ?? appStateSettings)["customCurrencyAmounts"]
            [currencyKey]
        .toDouble();
  } else if ((appStateSettingsPassed ??
          appStateSettings)["cachedCurrencyExchange"]?[currencyKey] !=
      null) {
    return (appStateSettingsPassed ??
            appStateSettings)["cachedCurrencyExchange"][currencyKey]
        .toDouble();
  } else {
    return 1;
  }
}

double budgetAmountToPrimaryCurrency(AllWallets allWallets, Budget budget) {
  return budget.amount *
      (amountRatioToPrimaryCurrencyGivenPk(allWallets, budget.walletFk));
}

double objectiveAmountToPrimaryCurrency(
    AllWallets allWallets, Objective objective) {
  return objective.amount *
      (amountRatioToPrimaryCurrencyGivenPk(allWallets, objective.walletFk));
}

double categoryBudgetLimitToPrimaryCurrency(
    AllWallets allWallets, CategoryBudgetLimit limit) {
  return limit.amount *
      (amountRatioToPrimaryCurrencyGivenPk(allWallets, limit.walletFk));
}

// Positive (input)
double getAmountRatioWalletTransferTo(AllWallets allWallets, String walletToPk,
    {String? enteredAmountWalletPk}) {
  return amountRatioFromToCurrency(
        allWallets
            .indexedByPk[
                enteredAmountWalletPk ?? appStateSettings["selectedWalletPk"]]!
            .currency!,
        allWallets.indexedByPk[walletToPk]!.currency!,
      ) ??
      1;
}

// Negative (output)
double getAmountRatioWalletTransferFrom(
    AllWallets allWallets, String walletFromPk,
    {String? enteredAmountWalletPk}) {
  return -1 *
      (amountRatioFromToCurrency(
            allWallets
                .indexedByPk[enteredAmountWalletPk ??
                    appStateSettings["selectedWalletPk"]]!
                .currency!,
            allWallets.indexedByPk[walletFromPk]!.currency!,
          ) ??
          1);
}
