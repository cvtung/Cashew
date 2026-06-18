import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/aboutPage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/noResults.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/outlinedButtonStacked.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/main.dart';
import 'package:provider/provider.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';

class ExchangeRates extends StatefulWidget {
  const ExchangeRates({super.key});

  @override
  State<ExchangeRates> createState() => _ExchangeRatesState();
}

class _ExchangeRatesState extends State<ExchangeRates> {
  String searchCurrenciesText = "";

  Future addCustomCurrency(String customKey) async {
    List<dynamic> customCurrencies = appStateSettings["customCurrencies"];
    customCurrencies.add(customKey);
    await updateSettings(
      "customCurrencies",
      customCurrencies,
      updateGlobalState: false,
    );
    setState(() {});
  }

  Future<DeletePopupAction?> deleteCustomCurrency(String customKey) async {
    DeletePopupAction? action = await openDeletePopup(
      context,
      title: "delete-currency-question".tr(),
      subtitle: customKey,
    );
    if (action == DeletePopupAction.Delete) {
      List<dynamic> customCurrencies = appStateSettings["customCurrencies"];
      customCurrencies.remove(customKey);
      await updateSettings(
        "customCurrencies",
        customCurrencies,
        updateGlobalState: false,
      );
      Map<dynamic, dynamic> customCurrencyAmountsMap =
          appStateSettings["customCurrencyAmounts"];
      customCurrencyAmountsMap.remove(customKey);
      updateSettings("customCurrencyAmounts", customCurrencyAmountsMap,
          updateGlobalState: false);
      setState(() {});
    }
    return action;
  }

  @override
  Widget build(BuildContext context) {
    Map<dynamic, dynamic> currencyExchange = {};
    List<dynamic> customCurrencies = appStateSettings["customCurrencies"];
    for (String key in customCurrencies) {
      currencyExchange[key] = null;
    }
    currencyExchange.addAll(appStateSettings["cachedCurrencyExchange"]);
    if (currencyExchange.keys.length <= 0) {
      for (String key in currenciesJSON.keys) {
        currencyExchange[key] = 1;
      }
    }

    // else {
    //   for (String key in [...customCurrencies, ...currencyExchange.keys]) {
    //     if (currenciesJSON.keys.contains(key) == false) {
    //       currencyExchange.remove(key);
    //     }
    //   }
    // }
    Map<dynamic, dynamic> currencyExchangeFiltered = {};
    if (searchCurrenciesText == "") {
      currencyExchangeFiltered = currencyExchange;
    } else {
      for (String key in currencyExchange.keys) {
        String? currencyCountry = currenciesJSON[key]?["CountryName"];
        String? currencyName = currenciesJSON[key]?["Currency"];
        if ((searchCurrenciesText.trim() == "" ||
            key.toLowerCase().contains(searchCurrenciesText.toLowerCase()) ||
            (currencyCountry != null &&
                currencyCountry
                    .toLowerCase()
                    .contains(searchCurrenciesText.toLowerCase())) ||
            (currencyName != null &&
                currencyName
                    .toLowerCase()
                    .contains(searchCurrenciesText.toLowerCase())))) {
          currencyExchangeFiltered[key] = currencyExchange[key];
        }
      }
    }

    return PageFramework(
      horizontalPaddingConstrained: true,
      dragDownToDismiss: true,
      title: "exchange-rates".tr(),
      actions: [
        IconButton(
          padding: EdgeInsetsDirectional.all(15),
          tooltip: "info".tr(),
          onPressed: () {
            openPopup(
              context,
              title: "exchange-rate-notice".tr(),
              description: "exchange-rate-notice-description".tr() +
                  "\n\n" +
                  "select-an-entry-to-set-custom-exchange-rate".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.info_outlined
                  : Icons.info_outline_rounded,
              onCancel: () {
                popRoute(context);
              },
              onCancelLabel: "ok".tr(),
            );
          },
          icon: Icon(
            appStateSettings["outlinedIcons"]
                ? Icons.info_outlined
                : Icons.info_outline_rounded,
          ),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: _GoldRateInfoBox(),
        ),
        SliverToBoxAdapter(
          child: AboutInfoBox(
            title: "exchange-rates-api".tr(),
            link: "https://github.com/fawazahmed0/exchange-api",
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 5),
            child: Row(
              children: [
                SizedBox(width: 15),
                Expanded(
                  child: TextInput(
                    labelText: "search-currencies-placeholder".tr(),
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.search_outlined
                        : Icons.search_rounded,
                    onChanged: (value) {
                      setState(() {
                        searchCurrenciesText = value;
                      });
                    },
                    autoFocus: false,
                    padding: EdgeInsetsDirectional.zero,
                  ),
                ),
                SizedBox(width: 10),
                ButtonIcon(
                  onTap: () {
                    openBottomSheet(
                      context,
                      popupWithKeyboard: true,
                      PopupFramework(
                        title: "add-currency".tr(),
                        child: SelectText(
                          buttonLabel: "add-currency".tr(),
                          icon: appStateSettings["outlinedIcons"]
                              ? Icons.account_balance_wallet_outlined
                              : Icons.account_balance_wallet_rounded,
                          setSelectedText: (_) {},
                          nextWithInput: (text) async {
                            addCustomCurrency(text);
                          },
                          selectedText: "",
                          placeholder: "currency".tr(),
                          autoFocus: true,
                        ),
                      ),
                    );
                  },
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.add_outlined
                      : Icons.add_rounded,
                ),
                SizedBox(width: 15),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: 5),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 17),
              child: TextFont(
                text: "select-an-entry-to-set-custom-exchange-rate".tr(),
                maxLines: 2,
                fontSize: 13,
                textColor: getColor(context, "textLight"),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: 7),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 17, vertical: 5),
              child: TextFont(
                text: "1 " +
                    Provider.of<AllWallets>(context)
                        .indexedByPk[appStateSettings["selectedWalletPk"]]!
                        .currency
                        .toString()
                        .allCaps,
                maxLines: 2,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        currencyExchangeFiltered.keys.length == 0
            ? SliverToBoxAdapter(
                child: NoResults(message: "no-currencies-found".tr()),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    String key = currencyExchangeFiltered.keys
                        .toList()[index]
                        .toString();
                    bool isCustomCurrency = customCurrencies.contains(key);
                    bool isUnsetCustomCurrency = isCustomCurrency &&
                        appStateSettings["customCurrencyAmounts"]?[key] == null;
                    String calculatedExchangeRateString = isUnsetCustomCurrency
                        ? "1"
                        : (1 /
                                ((amountRatioToPrimaryCurrency(
                                    Provider.of<AllWallets>(context), key))))
                            .toStringAsFixed(14);
                    return ScaledAnimatedSwitcher(
                      keyToWatch: (appStateSettings["customCurrencyAmounts"]
                              ?[key])
                          .toString(),
                      key: ValueKey(key),
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                            bottom: isCustomCurrency ? 5 : 0),
                        child: Tappable(
                          onTap: () async {
                            await openBottomSheet(
                              context,
                              SetCustomCurrency(currencyKey: key),
                            );
                            setState(() {});
                          },
                          color: isCustomCurrency ||
                                  appStateSettings["customCurrencyAmounts"]
                                          ?[key] ==
                                      null
                              ? Colors.transparent
                              : Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.symmetric(horizontal: 8),
                            child: OutlinedContainer(
                              enabled: isCustomCurrency,
                              filled: appStateSettings["customCurrencyAmounts"]
                                      ?[key] !=
                                  null,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: 7),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFont(
                                        text: "",
                                        maxLines: 3,
                                        richTextSpan: [
                                          TextSpan(
                                            text: (isUnsetCustomCurrency
                                                    ? " " + "1 USD"
                                                    : "") +
                                                " = " +
                                                calculatedExchangeRateString,
                                            style: TextStyle(
                                              color: getColor(context, "black"),
                                              fontFamily:
                                                  appStateSettings["font"],
                                              fontFamilyFallback: ['Inter'],
                                              fontSize: 16,
                                            ),
                                          ),
                                          TextSpan(
                                            text: " " + key.allCaps,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily:
                                                  appStateSettings["font"],
                                              fontFamilyFallback: ['Inter'],
                                              color: getColor(context, "black"),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCustomCurrency)
                                      IconButton(
                                        padding: EdgeInsetsDirectional.all(15),
                                        tooltip: "delete-currency".tr(),
                                        onPressed: () {
                                          deleteCustomCurrency(key);
                                        },
                                        icon: Icon(
                                          appStateSettings["outlinedIcons"]
                                              ? Icons.delete_outlined
                                              : Icons.delete_rounded,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: currencyExchangeFiltered.keys.length,
                ),
              ),
      ],
    );
  }
}

class SetCustomCurrency extends StatefulWidget {
  const SetCustomCurrency({required this.currencyKey, super.key});
  final String currencyKey;

  @override
  State<SetCustomCurrency> createState() => _SetCustomCurrencyState();
}

class _SetCustomCurrencyState extends State<SetCustomCurrency> {
  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "set-currency".tr(),
      // subtitle: "1 " +
      //     Provider.of<AllWallets>(context)
      //         .indexedByPk[appStateSettings["selectedWalletPk"]]!
      //         .currency
      //         .toString()
      //         .allCaps +
      //     " = ",
      subtitle: "1 USD = ",
      child: SelectAmountValue(
        allowZero: true,
        setSelectedAmount: (amount, amountString) {
          Map<dynamic, dynamic> customCurrencyAmountsMap =
              appStateSettings["customCurrencyAmounts"];
          if (amount == 0 || amountString == "") {
            customCurrencyAmountsMap.remove(widget.currencyKey);
          } else {
            // This will convert the primary currency to the custom currency
            // Issue: the selected currency may change, causing the custom currency to change
            // That is why we only allow the user to set the exchange rate of USD! since it is our reference
            // E.g. primary currency CAD, set custom currency of EUR to 5, then USD->CAD exchange rate changes when it's
            // pulled (the CAD exchange rate entry), the exchange rate for EUR will change, since it references USD!
            // double currentExchangeRate = getCurrencyExchangeRate(
            //     Provider.of<AllWallets>(context, listen: false)
            //         .indexedByPk[appStateSettings["selectedWalletPk"]]!
            //         .currency);
            // customCurrencyAmountsMap[widget.currencyKey] =
            //     currentExchangeRate * amount;
            customCurrencyAmountsMap[widget.currencyKey] = amount;
          }
          updateSettings("customCurrencyAmounts", customCurrencyAmountsMap,
              updateGlobalState: false);
        },
        // Convert amount passed into selected primary currency, read above why disabled
        // amountPassed: appStateSettings["customCurrencyAmounts"]
        //             ?[widget.currencyKey] ==
        //         null
        //     ? ""
        //     : removeTrailingZeroes((1 /
        //             getCurrencyExchangeRate(
        //                 (Provider.of<AllWallets>(context, listen: false)
        //                     .indexedByPk[appStateSettings["selectedWalletPk"]]!
        //                     .currency)) *
        //             (appStateSettings["customCurrencyAmounts"]
        //                     ?[widget.currencyKey] ??
        //                 1))
        //         .toString()),
        amountPassed: appStateSettings["customCurrencyAmounts"]
                    ?[widget.currencyKey] ==
                null
            ? ""
            : removeTrailingZeroes(appStateSettings["customCurrencyAmounts"]
                        ?[widget.currencyKey]
                    .toString() ??
                "0"),
        suffix: " " + widget.currencyKey.allCaps,
        nextLabel: "set-amount".tr(),
        next: () {
          popRoute(context);
        },
      ),
    );
  }
}

String? originalExchangeRatesBeforeOpenString;
void checkIfExchangeRateChangeBefore() {
  originalExchangeRatesBeforeOpenString =
      appStateSettings["customCurrencyAmounts"].toString();
}

bool checkIfExchangeRateChangeAfter() {
  // print(originalExchangeRatesBeforeOpenString);
  // print(appStateSettings["customCurrencyAmounts"].toString());
  if (originalExchangeRatesBeforeOpenString != null &&
      originalExchangeRatesBeforeOpenString !=
          appStateSettings["customCurrencyAmounts"].toString()) {
    print("There was a change to the custom currencies!");
    // Reset global state because currencies need to be reloaded
    appStateKey.currentState?.refreshAppState();
    originalExchangeRatesBeforeOpenString = null;
    return true;
  } else {
    return false;
  }
}

class _GoldRateInfoBox extends StatefulWidget {
  @override
  State<_GoldRateInfoBox> createState() => _GoldRateInfoBoxState();
}

class _GoldRateInfoBoxState extends State<_GoldRateInfoBox> {
  bool _loading = false;

  Future<void> _refreshGold() async {
    if (_loading) return;
    setState(() => _loading = true);
    Map<String, dynamic> result = await fetchGoldRate();
    setState(() => _loading = false);
    if (result["ok"] == true) {
      // Insert into cached exchange rates so conversions work immediately
      Map<dynamic, dynamic> cached = appStateSettings["cachedCurrencyExchange"];
      cached["luongvang"] = result["stored"];
      updateSettings("cachedCurrencyExchange", cached,
          updateGlobalState: true);
      openSnackbar(SnackbarMessage(
        title:
            "Gold rate updated: 1 lượng = ${(result["buyVndPerLuong"] as double).toStringAsFixed(0)} VND",
        icon: Icons.check_circle_outline,
      ));
    } else {
      openSnackbar(SnackbarMessage(
        title: "Could not fetch gold rate: ${result["error"]}",
        icon: Icons.error_outline,
        timeout: const Duration(seconds: 5),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? info = appStateSettings["goldRateInfo"];
    double? buyVnd = info?["buyVndPerLuong"];
    String? fetchedAt = info?["fetchedAt"];
    String? source = info?["source"];

    String rateLine;
    String timeLine;
    if (buyVnd == null) {
      rateLine = "Gold rate not fetched yet";
      timeLine = "Pull down to refresh, or wait for next sync";
    } else {
      String formatted = buyVnd.toStringAsFixed(0);
      String withSep = formatted.replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
      rateLine = "1 lượng vàng = $withSep VND";
      if (fetchedAt != null) {
        try {
          DateTime t = DateTime.parse(fetchedAt).toLocal();
          timeLine =
              "Updated ${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} "
              "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
        } catch (e) {
          timeLine = "Updated $fetchedAt";
        }
      } else {
        timeLine = "";
      }
    }

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 5),
      child: Tappable(
        onTap: () {
          if (source != null) openUrl(source);
        },
        onLongPress: () {
          if (source != null) copyToClipboard(source);
        },
        color: appStateSettings["materialYou"]
            ? dynamicPastel(context,
                Theme.of(context).colorScheme.secondaryContainer,
                amountLight: 0.2, amountDark: 0.6)
            : getColor(context, "lightDarkAccent"),
        borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 15,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 13, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monetization_on_outlined,
                    size: 18,
                    color: getColor(context, "textLight"),
                  ),
                  SizedBox(width: 6),
                  TextFont(
                    text: "Lượng vàng (BT9999NTT)",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(width: 6),
                  _loading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Tappable(
                          onTap: _refreshGold,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(4),
                            child: Icon(
                              Icons.refresh,
                              size: 18,
                              color: getColor(context, "textLight"),
                            ),
                          ),
                        ),
                ],
              ),
              SizedBox(height: 6),
              TextFont(
                text: rateLine,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              if (timeLine.isNotEmpty) ...[
                SizedBox(height: 4),
                TextFont(
                  text: timeLine,
                  fontSize: 12,
                  textAlign: TextAlign.center,
                  textColor: getColor(context, "textLight"),
                ),
              ],
              if (source != null) ...[
                SizedBox(height: 6),
                TextFont(
                  text: source,
                  fontSize: 11,
                  textAlign: TextAlign.center,
                  textColor: getColor(context, "textLight"),
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
