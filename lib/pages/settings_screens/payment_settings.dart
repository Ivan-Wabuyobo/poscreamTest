import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poscream/components/components.dart';
import 'package:poscream/constants.dart';
import 'package:poscream/services/api.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../components/databaseHelper.dart';

class PaymentSettings extends StatefulWidget {
  const PaymentSettings({Key? key}) : super(key: key);

  @override
  State<PaymentSettings> createState() => _PaymentSettingsState();
}

class _PaymentSettingsState extends State<PaymentSettings> {
  String? settingsId;
  String token = "";
  String? allowMultiplePayments = "1";
  String? allowCustomerDeposits;
  String? enableCreditLimit;
  String? depositCustomerBalances;

  fetchPaymentSettings() async {
    Database? db = await DatabaseHelper.instance.database;
    db?.query("settings").then((value) {
      setState(() {
        for (var setting in value) {
          settingsId = setting['settingsId'].toString();
          allowCustomerDeposits = setting["allowCustomerDeposits"].toString();
          enableCreditLimit = setting["enableCreditLimit"].toString();
          depositCustomerBalances =
              setting["depositCustomerBalances"].toString();
        }
      });
    });
  }

  Future<void> changeGeneralSettings(data) async {
    await Requests.changeGeneralSettings(token, data).then((value) async {
      if (value == "success") {
        fetchServerSettings(token).then((value) {
          fetchPaymentSettings();
        });
      } else if (value == "error") {
        await fetchPaymentSettings();
        if (context.mounted) {
          alertToast(context,
              message:
                  "Unable to change this setting.\nPlease check your internet connection and try again",
              title: "Error");
        }
      }
    });
  }

  void fetchBusinessAndUserDetails() {
    DatabaseHelper.instance.fetchBusinessDetails().then((value) {
      var data = value![0];
      setState(() {
        token = data['token'];
      });
    });
  }

  @override
  void initState() {
    super.initState();
    fetchPaymentSettings();
    fetchBusinessAndUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Payment Settings'),
                  tiles: <SettingsTile>[
                    SettingsTile.switchTile(
                      description: const Text(
                          "Enable this if would like to receive payment from different options like Mobile money, Bank, etc. Default is Cash"),
                      onToggle: (value) {},
                      initialValue: allowMultiplePayments == "1" ? true : false,
                      leading: const Icon(Icons.payments_sharp),
                      title: const Text('Enable Multiple Payment Options'),
                    ),
                    SettingsTile.navigation(
                      leading: const Icon(Icons.payment),
                      title: const Text('Default Payment Option'),
                      value: const Text('Cash'),
                    ),
                    SettingsTile.navigation(
                      leading: Container(
                        width: 25,
                      ),
                      description: const Text(
                        "NOTE: Cash payment Method is created automatically.",
                        style: TextStyle(
                            color: darkColor, fontWeight: FontWeight.bold),
                      ),
                      title: const Text('Manage Payment Options'),
                      // value: Text('Last 3 Weeks'),
                    ),
                    SettingsTile.switchTile(
                      description: const Text(
                          "This setting allows you to track prepaid customer accounts"),
                      onToggle: (value) async {
                        setState(() {
                          allowCustomerDeposits = value ? "1" : "0";
                        });
                        var data = {
                          "id": settingsId,
                          "column": "customer_deposit",
                          "status": value ? "1" : "0",
                        };
                        await changeGeneralSettings(data);
                      },
                      initialValue: allowCustomerDeposits == "1" ? true : false,
                      leading: const Icon(Icons.people_rounded),
                      title: const Text('Allow Customer Deposits'),
                    ),
                    SettingsTile.switchTile(
                      onToggle: (value) async {
                        setState(() {
                          enableCreditLimit = value ? "1" : "0";
                        });
                        var data = {
                          "id": settingsId,
                          "column": "enable_credit_limit",
                          "status": value ? "1" : "0",
                        };
                        await changeGeneralSettings(data);
                      },
                      initialValue: enableCreditLimit == "1" ? true : false,
                      description: const Text(
                          "This setting helps you to put a control on credit limit from Suppliers"),
                      leading: const Icon(Icons.money_outlined),
                      title: const Text('Enable Credit Limit'),
                    ),
                    SettingsTile.switchTile(
                      onToggle: (value) async {
                        setState(() {
                          depositCustomerBalances = value ? "1" : "0";
                        });
                        var data = {
                          "id": settingsId,
                          "column": "deposit_balances",
                          "status": value ? "1" : "0",
                        };
                        await changeGeneralSettings(data);
                      },
                      initialValue:
                          depositCustomerBalances == "1" ? true : false,
                      description: const Text(
                          "This setting helps you to store a customer's balance onto their account after sale"),
                      leading: const Icon(Icons.payments_outlined),
                      title: const Text('Deposit Customer Balances'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
