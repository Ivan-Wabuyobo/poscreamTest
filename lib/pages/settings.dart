import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poscream/constants.dart';
import 'package:poscream/pages/settings_screens/payment_settings.dart';
import 'package:poscream/pages/settings_screens/receipt_settings.dart';
import 'package:poscream/pages/settings_screens/sales_settings.dart';
import 'package:poscream/pages/settings_screens/users_settings.dart';
import 'package:text_divider/text_divider.dart';

import '../components/databaseHelper.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String? contact = "";
  String? username = "";
  void fetchBusinessAndUserDetails() {
    DatabaseHelper.instance.fetchBusinessDetails().then((value) {
      var data = value![0];
      setState(() {
        contact = data["userPhone1"];
        username = data["username"];
      });
    });
  }
  @override
  void initState() {
    super.initState();
    fetchBusinessAndUserDetails();
  }

  final drawerItems = [
    DrawerItem("Customize", Icons.settings, true),
    DrawerItem("General", Icons.settings, false),
    DrawerItem("Users", CupertinoIcons.person, false),
    DrawerItem("Sales", CupertinoIcons.cart, false),
    DrawerItem("Payment", CupertinoIcons.creditcard, false),
    DrawerItem("Receipt", Icons.receipt, false),
  ];
  int _selectedIndex=1;

  _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 1:
        return Container();
      case 2:
        return const UsersSettings();
      case 3:
        return const SalesSettings();
      case 4:
        return const PaymentSettings();
      case 5:
        return const ReceiptSettings();
      default:
        return const Text("Error");
    }
  }
  @override
  Widget build(BuildContext context) {
    var drawerOptions = <Widget>[
      Container(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: DrawerHeader(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/logo.png'),
              fit: BoxFit.contain,
            ),
          ),
          child: Container(),
        ),
      )
    ];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      drawerOptions.add(
          Column(
            children: [
              Container(
                // height: 80,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: i==_selectedIndex ? Colors.white : Colors.transparent,
                ),

                child: d.isDivider?
                TextDivider(text: Text(d.title),):
                ListTile(
                  leading:  Icon(d.icon),
                  title:  Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold),),
                  iconColor: Colors.black,
                  textColor: Colors.black,
                  selectedColor: loginColor,
                  selected: i == _selectedIndex,
                  onTap: (){
                    setState(() {
                      _selectedIndex = i;
                    });
                    // appState.selectedIndex = i;
                  },
                ),
              ),
              // SizedBox(height: 1, child: Container(color: Colors.white)),
            ],
          )
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 250,
              height: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.8,
                    colors: [Color(0xffd1d1d1), Color(0xffffffff)],
                    stops: [0, 1],
                    center: Alignment.centerRight,
                  )
                ,
                  ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: drawerOptions,
                ),
              ),
            ),
            Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      color: Colors.white,
                      child: Row(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('assets/images/profilex.png'),
                          ),
                          Column(
                            children:  [
                              Expanded(child: Align(
                                  alignment:Alignment.bottomLeft,
                                  child: Text("$username", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start,))),
                               Expanded(child: Align(
                                  alignment:Alignment.topLeft,
                                  child: Text("0$contact", style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14, color: Colors.grey), textAlign: TextAlign.start,)))
                            ],
                          )
                        ],
                      ),
                    ),
                    const Divider(
                      color: Colors.grey,
                    ),
                    Container(
                      height: 60,
                      padding: const EdgeInsets.only(left: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                          child: Text(drawerItems[_selectedIndex].title, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),textAlign: TextAlign.start,)),
                    ),
                    Expanded(
                        child: _getDrawerItemWidget(_selectedIndex)
                    )
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerItem {
  String title;
  IconData icon;
  bool isDivider;
  DrawerItem(this.title, this.icon, this.isDivider);
}