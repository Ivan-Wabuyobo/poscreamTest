import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poscream/components/components.dart';
import 'package:poscream/components/databaseHelper.dart';
import 'package:poscream/constants.dart';
import 'package:poscream/services/api.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:sqflite_common/sqflite.dart';

class ReceiptSettings extends StatefulWidget {
  const ReceiptSettings({Key? key}) : super(key: key);

  @override
  State<ReceiptSettings> createState() => _ReceiptSettingsState();
}

class _ReceiptSettingsState extends State<ReceiptSettings> {
  String token = "";
  String? receiptId;
  String? printReceiptAfterSale;
  String? indicateCustomerName;
  String? indicateUserOnReceipt;
  String? indicateContactsOnReceipt;
  String? indicateContacts;

  void fetchBusinessAndUserDetails() {
    DatabaseHelper.instance.fetchBusinessDetails().then((value) {
      var data = value![0];
      setState(() {
        token = data['token'];
      });
    });
  }

  Future<void> fetchReceiptSettings() async {
    Database? db = await DatabaseHelper.instance.database;
    db?.query("receiptSettings").then((value) {
      setState(() {
        for (var setting in value) {
          receiptId = setting["receiptSettingsId"].toString();
          printReceiptAfterSale = setting["printReceiptAfterSale"].toString();
          indicateCustomerName = setting["indicateCustomer"].toString();
          indicateUserOnReceipt = setting["indicateUser"].toString();
          indicateContacts = setting["indicateContacts"].toString();
        }
      });
    });
  }

  Future<void> changeReceiptSettings(data) async {
    await Requests.changeReceiptSettings(token, data).then((value) async {
      if (value == "success") {
        fetchServerReceiptSettings(token).then((value) {
          fetchReceiptSettings();
        });
      } else if (value == "error") {
        await fetchReceiptSettings();
        if(context.mounted)alertToast(context, message: "Unable to change this setting.\nPlease check your internet connection and try again", title: "Error");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchBusinessAndUserDetails();
    fetchReceiptSettings();
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
                  title: const Text('Receipt Settings'),
                  tiles: <SettingsTile>[
                    SettingsTile.switchTile(
                      description: const Text(
                          "This setting will enable receipt printing on sales Window"),
                      onToggle: (value) async {
                        setState(() {
                          printReceiptAfterSale = value ? "1" : "0";
                        });
                        var data = {
                          "id": receiptId,
                          "column": "print_receipt_after_sale",
                          "status": value ? "1" : "0",
                        };
                        await changeReceiptSettings(data);
                      },
                      initialValue: printReceiptAfterSale == "1" ? true : false,
                      leading: const Icon(Icons.print),
                      title: const Text('Print Receipt After Sale'),
                    ),
                    SettingsTile.switchTile(
                      description: const Text(
                          "When a customer is selected, their name will be displayed on the receipt"),
                      onToggle: (value) async {
                        setState(() {
                          indicateCustomerName = value ? "1" : "0";
                        });
                        var data = {
                          "id": receiptId,
                          "column": "indicate_customer",
                          "status": value ? "1" : "0",
                        };
                        await changeReceiptSettings(data);
                      },
                      initialValue: indicateCustomerName == "1" ? true : false,
                      leading: const Icon(Icons.person),
                      title: const Text('Indicate Customer Name'),
                    ),
                    SettingsTile.switchTile(
                      description: const Text(
                          "The logged-in User will be shown on the receipt "),
                      onToggle: (value) async {
                        setState(() {
                          indicateUserOnReceipt = value ? "1" : "0";
                        });
                        var data = {
                          "id": receiptId,
                          "column": "indicate_user",
                          "status": value ? "1" : "0",
                        };
                        await changeReceiptSettings(data);
                      },
                      initialValue: indicateUserOnReceipt == "1" ? true : false,
                      leading: const Icon(Icons.person),
                      title: const Text('Indicate User On Receipt'),
                    ),
                    SettingsTile.switchTile(
                      description: const Text(
                          "This enables displaying Business contacts on the receipt"),
                      onToggle: (value) async {
                        setState(() {
                          indicateContacts = value ? "1" : "0";
                        });
                        var data = {
                          "id": receiptId,
                          "column": "show_contacts",
                          "status": value ? "1" : "0",
                        };
                        await changeReceiptSettings(data);
                      },
                      initialValue: indicateContacts == "1" ? true : false,
                      leading: const Icon(Icons.phone),
                      title: const Text('Indicate Contacts On Receipt'),
                    ),
                    SettingsTile.switchTile(
                      description: const Text(
                          "This setting displays discount on Sales receipt"),
                      onToggle: (value) {
                        setState(() {
                          showDiscount = !showDiscount;
                        });
                      },
                      initialValue: showDiscount,
                      leading: const Icon(Icons.discount),
                      title: const Text('Show Discount on Receipt'),
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
