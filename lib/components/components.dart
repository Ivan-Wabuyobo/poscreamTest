import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common/sqlite_api.dart';
import '../services/api.dart';
import 'databaseHelper.dart';

class ProductsAndUnits {
  String id,
      product_id,
      item_id,
      productName,
      product_category,
      unitname,
      minimum,
      instock,
      selling,
      type,
      reserve,
      vat,
      code,
      buyingPrice,
      productNaming,
      unitServerId,
      product,
      unitId,
      unitName,
      unitSymbol,
      is_base,
      base_qty,
      product_code,
      sellingUnit,
      reserveUnit,
      wholesale_unitprice,
      wholesale_reserveprice;
  ProductsAndUnits(
    this.id,
    this.product_id,
    this.item_id,
    this.productName,
    this.product_category,
    this.unitname,
    this.minimum,
    this.instock,
    this.selling,
    this.type,
    this.reserve,
    this.vat,
    this.code,
    this.buyingPrice,
    this.productNaming,
    this.unitServerId,
    this.product,
    this.unitId,
    this.unitName,
    this.unitSymbol,
    this.is_base,
    this.base_qty,
    this.product_code,
    this.sellingUnit,
    this.reserveUnit,
    this.wholesale_unitprice,
    this.wholesale_reserveprice,
  );
}

bool showDiscount = true;
settingDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: StatefulBuilder(builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20.0),
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Expanded(
                          child: Text(
                              "System settings, Instructions and Short cuts",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20.0))),
                      Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close,
                              color: Colors.red[900],
                            ),
                          )),
                    ],
                  ),
                  Row(
                    children: const [
                      Expanded(
                        child: Text("To save and print"),
                      ),
                      Expanded(
                        child: Text("Press end"),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Expanded(
                        child: Text("To save and Exit"),
                      ),
                      Expanded(
                        child: Text("Press Page Down (pg dn)"),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Expanded(
                        child: Text("To Enter amount received"),
                      ),
                      Expanded(
                        child: Text("Press Escape (esc)"),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Expanded(
                        child: Text("To go back  to search product"),
                      ),
                      Expanded(
                        child: Text("Press  Page Up (pg up)"),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text("Show discount on Receipt"),
                      ),
                      Expanded(
                        flex: 3,
                        child: Switch(
                            value: showDiscount,
                            onChanged: (value) {
                              setState(() {
                                showDiscount = value;
                              });
                            }),
                      )
                    ],
                  )
                ],
              ),
            );
          }),
        );
      });
}

alertToast(BuildContext context,
    {String? message, String? title, String? type}) {
  if (type == "success") {
    CherryToast.success(
      toastDuration: const Duration(seconds: 5),
      title: Text("$title"),
      displayTitle: true,
      description: Text("$message"),
    ).show(context);
  } else {
    CherryToast.error(
      toastDuration: const Duration(seconds: 5),
      title: Text("$title"),
      displayTitle: true,
      description: Text("$message"),
    ).show(context);
  }
}

Future fetchServerProducts(token) async {
  try {
    Database? database = await DatabaseHelper.instance.database;
    final batch = database?.batch();
    batch?.delete(DatabaseHelper.productsAndUnits);
    await Requests.products(token).then((value) async {
      if (value == "error") {
        print("There was an error while fetching products");
      } else {
        for (var product in value) {
          for (var unit in product['units']) {
            var data = {
              "unit_server_id": unit['id'].toString(),
              "product": unit['product'],
              "unitId": unit['unit']['id'].toString(),
              "unitName": unit['unit']['name'],
              "unitSymbol": unit['unit']['symbol'],
              "is_base": unit['is_base'].toString(),
              "base_qty": unit['base_qty'].toString(),
              "product_code": unit['product_code'] ?? "",
              "unitSelling": unit['selling'].toString(),
              "unitReserve": unit['reserve'].toString(),
              "wholesale_unitprice": unit['wholesale_unitprice'].toString(),
              "wholesale_reserveprice":
                  unit['wholesale_reserveprice'].toString(),
              "product_id": product['id'].toString(),
              "productItemId": product['item_id'].toString(),
              "productName": product['name'],
              "product_category": product['product_category'],
              "productUnitName": product['unitname'],
              "minimum": product['minimum'].toString(),
              "instock": product['instock'].toString(),
              "selling": product['selling'].toString(),
              "type": product['type'].toString(),
              "reserve": product['reserve'].toString(),
              "vat": product['vat'].toString(),
              "code": product['code'] ?? "",
              "buyingPrice": product['stock']['buying_price'].toString(),
            };
            batch?.insert(DatabaseHelper.productsAndUnits, data);
          }
        }
        await batch?.commit();
      }
    });
  } catch (e) {
    print(e);
  }
}

Future fetchServerCustomers(token) async {
  try {
    Database? database = await DatabaseHelper.instance.database;
    final batch = database?.batch();
    //Fetch customers and insert into the database
    await Requests.customers(token).then((value) async {
      await DatabaseHelper.instance.deleteCustomerTable().then((v) async {
        for (var customer in value) {
          var customers = {
            'customerId': customer['id'],
            'name': customer['name'],
            'name2': customer['name2'],
            'phone': customer['phone'],
            'addedBy': customer['user']['name'],
            'addedOn': customer['addedon'],
            'balance': customer['balance']
          };
          batch?.insert(DatabaseHelper.customers, customers);
        }
        await batch?.commit(continueOnError: true, noResult: false);
      });
    });
  } catch (e) {
    print(e);
  }
}

Future fetchServerSettings(token) async {
  try {
    await Requests.fetchSettings(token).then((value) async {
      Database? database = await DatabaseHelper.instance.database;
      final batch = database?.batch();
      var settingsData = {
        "settingsId" : value['id'],
        "backDateSales": value['back_date_sales'],
        "saleHolding": value['sale_holding'],
        "allowNegativeStock": value['allow_negative_stock'],
        "setTotalAsPaid": value['set_total_as_paid'],
        "saleDiscount": value['sale_discount'],
        "showBranchName": value['show_branchname'],
        "allowWholesale": value['enable_wholeselling'],
        "allowCustomerDeposits": value['customer_deposit'],
        "enableCreditLimit": value['enable_credit_limit'],
        "depositCustomerBalances": value['deposit_balances'],
        "trackCustomers" : value["track_customers"]
      };
      batch?.delete(DatabaseHelper.settings);
      batch?.insert(DatabaseHelper.settings, settingsData);
      await batch?.commit();
    });
  } catch (e) {
    print(e);
  }
  //Fetch general settings
}

Future fetchServerPaymentMethods(token) async {
  try {
    await Requests.paymentMethods(token).then((value) async {
      Database? database = await DatabaseHelper.instance.database;
      final batch = database?.batch();
      batch?.delete('paymentMethods');
      for (var paymentMethod in value) {
        var paymentMethods = {
          'payid': paymentMethod['id'],
          'mode': paymentMethod['mode'],
          'name': paymentMethod['name'],
          'type': paymentMethod['type'],
          'typeName': paymentMethod['type_name'],
          'accountNumber': paymentMethod['anumber'],
          'isDefault': paymentMethod['default'],
          'balance': paymentMethod['balance'],
        };
        batch?.insert('paymentMethods', paymentMethods);
      }
      await batch?.commit();
    });
  } catch (e) {
    print(e);
  }
}

Future fetchServerReceiptSettings(token) async {
  try {
    await Requests.fetchReceiptSettings(token).then((value) async {
      // print("========value");
      // print("$value");
      // print("========value");
      Database? database = await DatabaseHelper.instance.database;
      final batch = database?.batch();
      batch?.delete('receiptSettings');
      var receiptSettings = {
        "receiptSettingsId": value['id'].toString(),
        "printReceiptAfterSale": value['print_receipt_after_sale'],
        "indicateWebsite": value['indicate_website'],
        "indicateBusinessName": value['indicate_business_name'],
        "indicateBranchName": value["indicate_branch_name"],
        "indicateCustomer": value['indicate_customer'],
        "indicateBusinessEmail": value['indicate_businessemail'],
        "indicateGoodsNotReturnable": value['indicate_goods_not_returnable'],
        "indicateUser": value["indicate_user"],
        "indicateContacts": value["show_contacts"],
      };
      batch?.insert('receiptSettings', receiptSettings);
      await batch?.commit();
    });
  } catch (e) {
    print("$e");
  }
}

class RightCursorTextEditingController extends TextEditingController {
  @override
  set text(String newText) {
    super.text = newText;
    _moveCursorToEnd();
  }

  void _moveCursorToEnd() {
    Future.delayed(const Duration(milliseconds: 1), () {
      selection = TextSelection.fromPosition(TextPosition(offset: text.length));
    });
  }
}
