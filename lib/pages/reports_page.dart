import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants.dart';

class Reports extends StatefulWidget {

  const Reports({Key? key}) : super(key: key);



  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final drawerItems = [
    DrawerItem("Sales Report", CupertinoIcons.cart),
    DrawerItem("Purchase Report", FontAwesomeIcons.boxesPacking),
    DrawerItem("Debtors Report", CupertinoIcons.person),
    DrawerItem("Creditors Report", CupertinoIcons.person_alt),
    DrawerItem("Stock Levels Report", Icons.inventory_2_outlined),
    DrawerItem("Accounts Report", Icons.wallet),
    DrawerItem("Trial Balance", Icons.list),
    DrawerItem("Balance Sheet", Icons.list),
    DrawerItem("Income Statement", Icons.list),
    DrawerItem("Shift Report", Icons.list),
    DrawerItem("Audit Trail", CupertinoIcons.search),
  ];
  int _selectedDrawerIndex = 0;

  _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return new Container();
      case 1:
        return new Container();
      case 2:
        return new Container();

      default:
        return new Text("Error");
    }
  }

  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    // Navigator.of(context).pop(); // close the drawer
  }

  Color activeTextColor = kPrimaryColor; // Dark blue color for active tiles
  Color activeBgColor = Colors.white; // Dark blue color for active tiles
  Color inactiveTextColor = Colors.white;
  Color inactiveBgColor = kPrimaryColor;


  @override
  Widget build(BuildContext context) {
    var drawerOptions = <Widget>[];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      drawerOptions.add(
           Column(
             children: [
               Container(
                 color: i==_selectedDrawerIndex ? Colors.white : kPrimaryColor,
                 child: ListTile(
                  leading:  Icon(d.icon),
                  title:  Text(d.title),
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  selectedColor: kPrimaryColor,
                  selected: i == _selectedDrawerIndex,
                  onTap: () => _onSelectItem(i),
          ),
               ),
               SizedBox(height: 1, child: Container(color: Colors.white)),
             ],
           )
      );
    }
    return Scaffold(
      // appBar: AppBar(title: const Text("Reports"), backgroundColor: kPrimaryColor,),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: kPrimaryColor
            ),
            height: 50,
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                    child: Container(
                  padding: const EdgeInsets.all(10),
                    child: const Text("Diamond Supermarket", style: TextStyle(color:Colors.white, fontSize: 18)))),
                Expanded(
                  flex: 8,
                  child: Container(
                    child: Text(drawerItems[_selectedDrawerIndex].title,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
                
                Expanded(
                  flex: 2,
                  child: Container(
                    child: TextButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      }, child: const Text("Back to Sales", style: TextStyle(color: Colors.white),),
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
              child: Row(
                children: [
            Expanded(
              flex: 3,
              child: Container(
                height: MediaQuery.of(context).size.height,
                color: kPrimaryColor,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: drawerOptions,
                  ),
                )

                ,
              ),
            ),
            Expanded(
              flex: 10,
              child: Container(),
            ),
          ],
        ))
        ],
      ),
    );
  }
}

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}