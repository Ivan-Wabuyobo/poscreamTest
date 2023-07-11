import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poscream/constants.dart';
import 'package:poscream/pages/customers.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../components/components.dart';
import '../../components/databaseHelper.dart';
import '../../services/api.dart';

class SalesSettings extends StatefulWidget {
  const SalesSettings({Key? key}) : super(key: key);

  @override
  State<SalesSettings> createState() => _SalesSettingsState();
}

class _SalesSettingsState extends State<SalesSettings> {
  String token = "";
  String? contact = "";
  String? username = "";
  String? settingsId;
  String? enableWholeSale;
  String? giveDiscount;
  String? backDateSales;
  String? cartHolding;
  String? trackCustomers;
  String? allowNegativeStock;
  String? totalAsDefaultPaid;

  fetchSettings() async {
    Database? db = await DatabaseHelper.instance.database;
    db?.query("settings").then((value) {
      setState(() {
        for (var setting in value) {
          settingsId = setting['settingsId'].toString();
          enableWholeSale = setting["allowWholesale"].toString();
          giveDiscount = setting["saleDiscount"].toString();
          backDateSales = setting["backDateSales"].toString();
          cartHolding = setting["saleHolding"].toString();
          trackCustomers = setting["trackCustomers"].toString();
          allowNegativeStock = setting["allowNegativeStock"].toString();
          totalAsDefaultPaid = setting["setTotalAsPaid"].toString();
        }
      });
    });
  }

  Future<void> changeGeneralSettings(data) async {
    await Requests.changeGeneralSettings(token, data).then((value) async {
      if (value == "success") {
        fetchServerSettings(token).then((value) {
          fetchSettings();
        });
      } else if (value == "error") {
        await fetchSettings();
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
        token = data["token"];
        contact = data["userPhone1"];
        username = data["username"];
      });
    });
  }

  @override
  void initState() {
    super.initState();
    fetchBusinessAndUserDetails();
    fetchSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(child: SettingsList(
            sections: [
              SettingsSection(
                title: const Text('General'),
                tiles: <SettingsTile>[
                  SettingsTile.switchTile(
                    description: const Text("Enable this if you have wholesale prices set"),
                    onToggle: (value) async {
                      setState(() {
                        enableWholeSale = value ? "1" : "0";
                      });
                      var data = {
                        "id": settingsId,
                        "column": "enable_wholeselling",
                        "status": value ? "1" : "0",
                      };
                      await changeGeneralSettings(data);
                    },
                    initialValue: enableWholeSale == "1" ? true : false,
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text('Enable WholeSale'),
                  ),
                  SettingsTile.switchTile(
                    description: const Text("This enables discount calculation and deduction during sales entry"),
                    onToggle: (value) async {
                      setState(() {
                        giveDiscount = value ? "1" : "0";
                      });
                      var data = {
                        "id": settingsId,
                        "column": "sale_discount",
                        "status": value ? "1" : "0",
                      };
                      await changeGeneralSettings(data);
                    },
                    initialValue: giveDiscount == "1" ? true : false,
                    leading: const Icon(Icons.discount),
                    title: const Text('Enable Sales Discount'),
                  ),
                  SettingsTile.switchTile(
                    onToggle: (value) async {
                      setState(() {
                        backDateSales = value ? "1" : "0";
                      });
                      var data = {
                        "id": settingsId,
                        "column": "back_date_sales",
                        "status": value ? "1" : "0",
                      };
                      await changeGeneralSettings(data);
                    },
                    initialValue: backDateSales == "1" ? true : false,
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Back-date Sales'),
                  ),
                  SettingsTile.navigation(
                    enabled: false,
                    leading: Container(width: 25,),
                    description: const Text(""),
                    title: const Text(''),
                    value: const Text(''),
                  ),
                  SettingsTile.switchTile(
                    onToggle: (value) async {
                      setState(() {
                        cartHolding = value ? "1" : "0";
                      });
                      var data = {
                        "id": settingsId,
                        "column": "sale_holding",
                        "status": value ? "1" : "0",
                      };
                      await changeGeneralSettings(data);
                    },
                    initialValue: cartHolding == "1" ? true : false,
                    description: const Text("This setting helps you to hold a cart session temporarily to first work on another session"),
                    leading: const Icon(Icons.shopping_cart_sharp),
                    title: const Text('Enable Cart-holding'),
                  ),
                  SettingsTile.switchTile(
                    onToggle: (value) async {
                      setState(() {
                        trackCustomers = value ? "1" : "0";
                      });
                      var data = {
                        "id": settingsId,
                        "column": "track_customers",
                        "status": value ? "1" : "0",
                      };
                      await changeGeneralSettings(data);
                    },
                    initialValue: trackCustomers == "1" ? true : false,
                    // description: Text("This setting helps you to hold a cart session temporarily to first work on another session"),
                    leading: const Icon(Icons.people),
                    title: const Text('Enable Customer Tracking'),
                  ),
                  SettingsTile.navigation(
                    leading: Container(width: 25,),
                    description: Column(
                      children: const [
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text("This setting enables Tracking customers.")),
                        Align(
                            alignment: Alignment.centerLeft,
                            child:
                            Text(
                                "NOTE: If this setting is turned off, Credit sales are automatically turned off.",
                              style: TextStyle(color: darkColor, fontWeight: FontWeight.bold),
                            )),
                      ],
                    ),
                    title: const Text('Manage Customers'),
                    onPressed: (context){
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
                        return const Customers();
                      }));
                    },
                    // value: Text('Last 3 Weeks'),
                  ),
                  SettingsTile.switchTile(
                    onToggle: (value) async {
                      setState(() {
                        allowNegativeStock = value ? "1" : "0";
                      });
                      var data = {
                        "id": settingsId,
                        "column": "allow_negative_stock",
                        "status": value ? "1" : "0",
                      };
                      await changeGeneralSettings(data);
                    },
                    initialValue: allowNegativeStock == "1" ? true : false,
                    description: const Text("This setting allows you to record sales even when out of stock"),
                    leading: const Icon(CupertinoIcons.cart_badge_minus),
                    title: const Text('Enable Negative Stock'),
                  ),
                  SettingsTile.switchTile(
                    onToggle: (value) {},
                    initialValue: totalAsDefaultPaid == "1" ? true : false,
                    description: const Text("This setting defualts the total paid field to the net total amount, after deducting Discount"),
                    leading: const Icon(Icons.payment),
                    title: const Text('Set Net Total as Default Paid'),
                  ),
                ],
              ),
            ],
          ),),
        ],
      ),
    );
  }
}
