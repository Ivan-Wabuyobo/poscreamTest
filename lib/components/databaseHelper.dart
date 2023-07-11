import 'dart:io';
import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poscream/components/components.dart';
import 'package:poscream/services/api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._();
  String token = '';
  static const databaseName = 'poscreamDatabase90000009.db';
  static const userTable = 'userTable';
  static const cartTable = 'cartTable';
  static const productsAndUnits = 'products';
  static const customers = 'customers';
  static const paymentMethods = 'paymentMethods';
  static const saleCart = 'saleCart';
  static const saleTable = 'saleTable';
  static const settings = 'settings';
  static const holdCart = 'holdCart';
  static const holdIdentification = 'holdIdentification';
  static const receiptSettings = 'receiptSettings';

  DropdownEditingController<Map<String, dynamic>>? paymentController = DropdownEditingController();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;
  var factory = databaseFactoryFfi;
  Future<Database?> get database async =>
      _database ??= await initializeDatabase();
  initializeDatabase() async {
    sqfliteFfiInit();
    Directory dir = await getApplicationSupportDirectory();
    String pathDir = dir.path;

    var localDbPath = join(pathDir, 'poscream_database');

    await factory.setDatabasesPath(localDbPath);
    return await factory.openDatabase(databaseName,
        options: OpenDatabaseOptions(
            version: 2,
            onCreate: (db, version) async {
              await db.execute(
                  "CREATE TABLE $userTable (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, userId TEXT, username TEXT, userStatus TEXT, userPhone1 TEXT, email TEXT, fullName TEXT,  token TEXT, businessId TEXT, businessName TEXT, businessAddress TEXT, businessLogo TEXT, businessPhone1 TEXT,businessPhone2 TEXT,  businessTin TEXT, businessStatus TEXT, branchId TEXT, branchName TEXT, branchAddress TEXT, branchPhone1 TEXT, branchPhone2 TEXT,branchStatus TEXT, loginStatus TEXT, editSellingPrice TEXT, viewGeneralSettings TEXT, viewReceiptSettings TEXT)");

              await db.execute(
                  "CREATE TABLE $productsAndUnits (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, unit_server_id TEXT, product TEXT, unitId TEXT, unitName TEXT, unitSymbol TEXT,  is_base TEXT, base_qty TEXT, product_code TEXT, unitSelling TEXT, unitReserve TEXT, wholesale_unitprice TEXT, wholesale_reserveprice TEXT, product_id TEXT, productItemId TEXT, productName TEXT, product_category TEXT, productUnitName TEXT,  minimum TEXT, instock TEXT, selling TEXT, type TEXT, reserve TEXT,  vat TEXT, code TEXT, buyingPrice TEXT  )");

              await db.execute(
                  "CREATE TABLE $cartTable (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, productName TEXT, quantity TEXT, quantityTaken TEXT, unitName TEXT, sellingPrice TEXT,  totalPrice TEXT, product TEXT, type TEXT, batch TEXT, unit TEXT, description TEXT, saleType TEXT, status Text)");
              await db.execute(
                  "CREATE TABLE $saleCart (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, productName TEXT NOT NULL, quantity TEXT NOT NULL, quantityTaken TEXT NOT NULL, unitName TEXT, sellingPrice TEXT NOT NULL,  totalPrice TEXT NOT NULL, product TEXT, type TEXT, batch TEXT, unit TEXT, description TEXT, saleType TEXT, status Text, saleId TEXT)");
              await db.execute(
                  "CREATE TABLE $saleTable (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, paid TEXT, total TEXT, discount TEXT, customer TEXT, saleDate TEXT, mode TEXT,  pickingDate TEXT, typeStatus TEXT, balance TEXT, transactionStatus TEXT, userId TEXT, customerName Text, customerContact TEXT, receipt TEXT,  status TEXT)");
              await db.execute(
                  "CREATE TABLE $customers (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, customerId TEXT, name TEXT, name2 TEXT, phone TEXT, addedBy TEXT, addedOn TEXT, balance TEXT)");
              await db.execute(
                  "CREATE TABLE $paymentMethods (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, payId TEXT, mode TEXT, name TEXT, type TEXT, typeName TEXT,  accountNumber TEXT, isDefault TEXT, balance TEXT)");

              await db.execute(
                  "CREATE TABLE $holdCart (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, productName TEXT, quantity TEXT, quantityTaken TEXT, unitName TEXT, sellingPrice TEXT,  totalPrice TEXT, product TEXT, type TEXT, batch TEXT, unit TEXT, description TEXT, saleType TEXT, status Text, identificationId Text)");

              await db.execute(
                  "CREATE TABLE $holdIdentification (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, identification TEXT, dateTime TEXT)");
              await db.execute(
                  "CREATE TABLE $settings (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, settingsId TEXT, backDateSales TEXT, saleHolding TEXT, saleDiscount TEXT, setTotalAsPaid TEXT, allowNegativeStock TEXT, showBranchName TEXT, allowWholesale Text, allowCustomerDeposits TEXT, enableCreditLimit TEXT, depositCustomerBalances TEXT, trackCustomers TEXT )");
              await db.execute(
                  "CREATE TABLE $receiptSettings (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, receiptSettingsId TEXT, printReceiptAfterSale TEXT, indicateWebsite TEXT, indicateBusinessName TEXT, indicateBranchName TEXT, indicateCustomer TEXT, indicateBusinessEmail TEXT, indicateGoodsNotReturnable TEXT, indicateContacts Text, indicateUser Text)");
            }));
  }

  //This function fetches business details and logged user details
  Future<List<Map<String, dynamic>>?> fetchBusinessDetails() async {
    Database? db = await instance.database;
    var results = await db?.rawQuery("SELECT * FROM userTable ");
    for (var result in results!) {
      token = result['token'].toString();
    }
    return results;
  }

  //This function fetches business products plus their respective units
  Future<List<Map<String, dynamic>>?> fetchProductsAndUnits() async {
    Database? db = await instance.database;
    var results = await db?.rawQuery("SELECT * FROM products");
    return results;
  }

  // This function fetches all products in the cart table
  Future<List<Map<String, dynamic>>?> fetchCartItems() async {
    Database? db = await instance.database;
    var results = await db?.rawQuery("SELECT * FROM cartTable");
    return results;
  }

  //This function inserts products to cart
  Future addCart(var data) async {
    Database? db = await instance.database;
    var results = await db?.insert('cartTable', data);
    return results;
  }

  //This function removes a product from cart
  Future removeFromCart(var product) async {
    Database? db = await instance.database;
    var results = await db?.delete('cartTable', where: 'id=$product');
    return results;
  }

  //This function removes all items from cart
  Future deleteCart() async {
    Database? db = await instance.database;
    await db?.delete('cartTable');
  }

  //This function checks whether an item exists in cart
  Future checkProductInCart(var unit) async {
    Database? db = await instance.database;
    var results = await db?.query('cartTable', where: 'unit = $unit');
    return results;
  }

  //This function updates/edits  cart
  Future updateCart(
      {id, String? quantity, String? totalPrice, String? sellingPrice}) async {
    Database? db = await instance.database;
    if (quantity != null) {
      var results = await db?.update(
          'cartTable', {'quantity': quantity, 'totalPrice': totalPrice},
          where: 'id = $id');
      return results;
    } else if (sellingPrice != null) {
      var results = await db?.update(
          'cartTable', {'sellingPrice': sellingPrice, 'totalPrice': totalPrice},
          where: 'id = $id');
      return results;
    }
  }

  //This function inserts a fresh sale into the sale Table
  Future addSale(var saleData) async {
    Database? db = await instance.database;
    Future saleId;
    try {
      await db!.transaction((txn) {
        saleId = txn.insert(saleTable, saleData).then((saleId) {
          saleId = saleId;
          //remove items from cart table and insert into the saleCart
          db.query(cartTable).then((value) {
           if(value.isNotEmpty){
             for (var product in value) {
               var data = {
                 'productName': product['productName'],
                 'quantity': product['quantity'],
                 'quantityTaken': product['quantityTaken'],
                 'unitName': product['unitName'],
                 'sellingPrice': product['sellingPrice'],
                 'totalPrice': product['totalPrice'],
                 'product': product['product'],
                 'type': product['type'],
                 'batch': product['batch'],
                 'unit': product['unit'],
                 'description': product['description'],
                 'saleType': product['saleType'],
                 'status': product['status'],
                 'saleId': saleId,
               };
               //insert the data
               txn.insert(saleCart, data).then((value) {});
             }
             txn.delete(cartTable);
           }else{
            txn.delete(saleTable, where: "id = $saleId");
           }
          });
        });
        return saleId;
      });
    } catch (e) {
      // Rollback the transaction
      print(e);

    }
  }

  //This function fetches payment methods
  Future fetchPaymentMethods() async {
    Database? db = await instance.database;
    var results =  await db?.query('paymentMethods');
    return results;
  }

  //This function fetches  customers
  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    Database? db = await instance.database;
    List<Map<String, dynamic>> customers = [];
    await db?.query('customers').then((value) {
      customers.clear();
      for (var element in value) {
        String balance = "";
        if (double.parse(element['balance'].toString()) > 0) {
          balance = "\nBalance of " "${element['balance']}";
        } else {
          balance = "\nAdvance of " "${element['balance']}";
        }
        customers.add({
          'name': element['name'],
          "balance": "${element['balance']}",
          "contact": "${element['phone']}",
          "customerId": element['customerId'].toString(),
        });
      }
    });
    return customers;
  }

  //This function fetches  customers
  Future<List<Map<String, dynamic>>?> fCustomers() async {
    Database? db = await instance.database;
    var results = await db?.query('customers');
    return results;
  }

  //This function fetches  a batch of unsynchronized sales
  Future batchSynchronizer() async {
    Database? db = await instance.database;
    fetchBusinessDetails();
    List<Map<String, Object?>?> saleData = [];
    await db?.query(saleTable, where: 'status = 0').then((value) async {
      for (var sale in value) {
        await db
            ?.query(saleCart, where: "saleId = ${sale['id']}")
            .then((cartItems) {
          List<Map<String, Object?>> cartData = [];
          cartData.clear();
          for (var item in cartItems) {
            cartData.add({
              'quantity': item['quantity'],
              'quantity_taken': item['quantityTaken'],
              'selling_price': item['sellingPrice'],
              'total_price': item['totalPrice'],
              'product_id': item['product'],
              'type': item['type'],
              'productName': item['productName'],
              'unitName': item['unitName'],
              'unit': item['unit'],
              'description': item['description'],
              'batch': '',
              'saleType': '1',
            });
          }
          saleData.add({
            "sale_id": sale['id'],
            "paid": sale['paid'],
            "total": sale['total'],
            "mode": sale['mode'],
            "discount": sale['discount'],
            "customer": sale['customer'],
            "sale_date": sale['saleDate'],
            "picking_date": sale['pickingDate'],
            "transaction_status": sale['transactionStatus'],
            "receipt": sale['receipt'],
            "cartItems": cartData
          });
        });
      }
    });
    //Submit the sales online
    await Requests.submitBatchSales(token, saleData).then((value) async {
      //if the request is successful then we update the sales table
      for(var saleId in value){
        await DatabaseHelper.instance.updateSaleTable(saleId);
      }
    });
    await fetchServerProducts(token);
  }


  //This function updates the sales table if the sale was successfully submitted to the online server
  Future updateSaleTable(var saleId) async {
    Database? db = await instance.database;
    db?.update(saleTable, {'status': '1'}, where: 'id = $saleId');
  }

  //This function fetches un synchronized sales
  Future countUnSynchronized() async {
    Database? db = await instance.database;
    var cnt = 0;
    await db!.rawQuery("SELECT count(id) as count  from saleTable where status=0").then((value) {
      cnt = int.parse(value.first['count'].toString());
    });
    return cnt;
  }

  //Fetch all sale items in the database
  Future fetchSaleItems() async {
    Database? db = await instance.database;
    var saleItems = [];
    await db?.query(saleTable, orderBy: "id DESC").then((value) {
      saleItems = value;
    });
    return saleItems;
  }

  //Fetch cart items  of a particular sale from the database
  Future cartItems(var saleId) async {
    Database? db = await instance.database;
    var cart = [];
    await db?.query('saleCart', where: 'saleId = $saleId').then((value) {
      cart = value;
    });
    return cart;
  }

  //This function implements cart holding
  Future cartHold(var identification) async {
    Database? db = await instance.database;
    var identificationData = {
      'identification': identification,
      'dateTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
    };
    db?.insert(holdIdentification, identificationData).then((value) async {
      var identificationId = value;
      await db?.query(cartTable).then((value) async {
        for (var product in value) {
          //insert into the hold cart
          var data = {
            'productName': product['productName'],
            'quantity': product['quantity'],
            'quantityTaken': product['quantityTaken'],
            'unitName': product['unitName'],
            'sellingPrice': product['sellingPrice'],
            'totalPrice': product['totalPrice'],
            'product': product['product'],
            'type': product['type'],
            'batch': product['batch'],
            'unit': product['unit'],
            'description': product['description'],
            'saleType': product['saleType'],
            'status': product['status'],
            'identificationId': identificationId,
          };

          await db.insert(holdCart, data);
        }
        await deleteCart();
      });
    });
  }

  //This function fetches cart items on hold
  Future fetchHoldCartItems() async {
    List<HoldData> holdData = [];
    List<Map<String, Object?>>? cartItems = [];

    Database? db = await instance.database;
    final batch = db?.batch();
    await db?.query(holdIdentification).then((value) async {
      holdData.clear();
      cartItems?.clear();
      for (var item in value) {
        cartItems = await db?.query(holdCart,
            where: "identificationId = '${item['id']}'");
        holdData.add(HoldData(
          id: item['id'].toString(),
          description: item['identification'].toString(),
          date: item['dateTime'].toString(),
          cartItems: cartItems,
        ));
      }
    });
    return holdData;
  }

  //This function un holds items from the hold cart
  Future unHoldCartItems(var id) async {
    Database? db = await instance.database;
    await db
        ?.query(holdCart, where: 'identificationId = $id')
        .then((cartData) async {
      await deleteCart().then((value) async {
        for (var item in cartData) {
          var data = {
            'productName': item['productName'],
            'quantity': item['quantity'],
            'quantityTaken': item['quantityTaken'],
            'unitName': item['unitName'],
            'sellingPrice': item['sellingPrice'],
            'totalPrice': item['totalPrice'],
            'product': item['product'],
            'type': item['type'],
            'batch': item['batch'],
            'unit': item['unit'],
            'description': item['description'],
            'saleType': item['saleType'],
            'status': item['status']
          };
          await db.insert(cartTable, data).then((value) {});
        }
      });
      await db.delete(holdIdentification, where: 'id = $id').then((value) {
        db.delete(holdCart, where: 'identificationId = $id');
      });
    });
  }

  //This function deletes cart items on hold
  Future deleteHoldItem(var id) async {
    Database? db = await instance.database;
    db?.delete(holdIdentification, where: "id = $id").then((value) {
      db?.delete(holdCart, where: "identificationId = $value");
    });
  }

  //This function performs a logout functionality cart items on hold
  Future logout() async {
    Database? db = await instance.database;
    await db?.delete(userTable);
  }

  Future fetchSettings() async {
    Database? db = await instance.database;
    var data = db?.query(settings);
    return data;
  }

  Future deleteCustomerTable() async {
    Database? db = await instance.database;
    await db?.delete(customers);
  }
}

class HoldData {
  String? id;
  String? description;
  String? date;
  List<Map<String, Object?>>? cartItems;

  HoldData({this.id, this.description, this.date, this.cartItems});
}
