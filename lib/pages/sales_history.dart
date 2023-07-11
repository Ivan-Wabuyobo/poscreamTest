import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:poscream/components/databaseHelper.dart';
import 'package:sqflite_common/sqlite_api.dart';
import '../components/printing_component.dart';
import '../constants.dart';

class SalesHistory extends StatefulWidget {
  const SalesHistory({Key? key}) : super(key: key);

  @override
  State<SalesHistory> createState() => _SalesHistoryState();
}

class _SalesHistoryState extends State<SalesHistory> {

  int selectedRow = -1;
  String grossAmount = "";
  String discount = "";
  String totalPaid = "";
  var saleId = "";

  PosPrinter printReceipt = PosPrinter();
  List<SaleItems> saleItems = [];
  List<SaleItems> searchedSaleItems = [];
  List<CartItem> cartItems = [];
  String dropDownOption = 'All';

  List<FilterOptions> filterOptions = [
    FilterOptions("Date Descending", "DD"),
    FilterOptions("Date Ascending", "DA"),
    FilterOptions("synchronized sales", "s"),
    FilterOptions("Non synchronized sales", "un"),
  ];
  int selectedOption = 0;
  // List<DataRow> filteredRows = [];
  List<DataRow> rows = [];

  fetchSaleItems() {
    DatabaseHelper.instance.fetchSaleItems().then((value) {
      saleItems.clear();
      searchedSaleItems.clear();
      var sn = 0;
      for (var sale in value) {
        sn = sn + 1;
        setState(() {
          saleItems.add(SaleItems(
              id: sale['id'].toString(),
              total: sale['total'],
              paid: sale['paid'],
              discount: sale['discount'],
              receipt: sale['receipt'],
              saleDate: sale['saleDate'],
              status: sale['status'],
              customer: sale['customerName']));
        });
      }
      setState(() {
        searchedSaleItems = saleItems;
      });
    });
  }

  fetchCart(var saleId) async {
    await DatabaseHelper.instance.cartItems(saleId).then((value) {
      cartItems.clear();
      for (var product in value) {
        setState(() {
          cartItems.add(CartItem(
              productName: product['productName'],
              quantity: '${product['quantity']}',
              price: product['sellingPrice'],
              subTotal: product['totalPrice']));
        });
      }
    });
  }
  Future clearSaleHistory() async {
    Database? database = await DatabaseHelper.instance.database;
    final batch = database?.batch();
    database?.delete(DatabaseHelper.saleTable, where: "status = 1").then((id) {
      batch?.delete('saleCart', where: 'saleId = $id');
    });
    batch?.commit;
  }

  Widget createTable() {
    List<DataColumn> columns = [
      const DataColumn2(label: Text("SN"), size: ColumnSize.S),
      const DataColumn2(label: Text("Date")),
      const DataColumn2(
        label: Text("Receipt No"),
      ),
      const DataColumn2(label: Text("Customer")),
      const DataColumn2(label: Text("Sale Total"), numeric: true),
      const DataColumn2(label: Text("Discount"), numeric: true),
      const DataColumn2(label: Text("Paid"), numeric: true),
      const DataColumn2(label: Text("Balance"), numeric: true),
      const DataColumn2(label: Text("Sync Status"), numeric: true),
    ];

    rows = searchedSaleItems.map((item) {
      int index = searchedSaleItems.indexOf(item);
      return DataRow(
        selected: selectedRow == index,
          onSelectChanged: (value) {
            setState(() {
              selectedRow = index;
              fetchCart(item.id);
              grossAmount = item.total!;
              discount = item.discount!;
              totalPaid = item.paid!;
              saleId = item.id.toString();
            });
          },
          color: MaterialStateColor.resolveWith(

              (states) {
                if (selectedRow == index) {
                  return Colors.deepOrange; // Customize the highlight color here
                }
                return index % 2 == 1 ? kPrimaryLightColor : Colors.white;
              }),
          cells: [
            DataCell(Text("${index + 1}",style: TextStyle(fontSize: 16.0),)),
            DataCell(Text(item.saleDate.toString(), style: TextStyle(fontSize: 16.0))),
            DataCell(Text(item.receipt.toString(), style: TextStyle(fontSize: 16.0))),
            DataCell(Text(item.customer.toString(), style: TextStyle(fontSize: 16.0))),
            DataCell(Text(item.total.toString(), style: TextStyle(fontSize: 16.0))),
            DataCell(Text(item.discount.toString(), style: TextStyle(fontSize: 16.0))),
            DataCell(Text(item.paid.toString(), style: TextStyle(fontSize: 16.0))),
            DataCell(Text(
                "${double.parse(item.total.toString()) - double.parse(item.discount.toString()) - double.parse(item.paid.toString())}")),
            DataCell(item.status == "1" ? const Icon(Icons.check, color: Colors.green, size: 40,): const Icon(Icons.close, color: Colors.redAccent, size: 40,)),

          ]);
    }).toList();
    // filteredRows = rows;

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: DataTable(
              headingTextStyle: const TextStyle(color: Colors.white),
              columns: columns,
              showCheckboxColumn: true,
              showBottomBorder: false,
              headingRowColor:
                  MaterialStateColor.resolveWith((states) => kPrimaryColor),
              rows: rows),
        ),
      ),
    );
  }

  void reprintReceipt(saleId) async {
    //Check if the printer is connected

    if (printReceipt.isConnected) {
      //Fetch cart Items with saleId
      await fetchCart(saleId);
      //Get sale Details
      var saleDetails = saleItems.firstWhere((element) {
        return element.id == saleId;
      });

      //Reprint the receipt
      var saleData = {
        "saleDate": saleDetails.saleDate,
        "receipt": saleDetails.receipt,
        "paid": saleDetails.paid,
        "total": saleDetails.total,
        "netTotal": double.parse(saleDetails.total!.replaceAll(',', '')) -
            double.parse(saleDetails.discount!.replaceAll(',', '')),
        "discount": saleDetails.discount,
        "cartItems": cartItems,
        "customer": saleDetails.customer
      };
      printReceipt.printReceipt(saleData);
    } else {
      printReceipt.selectPrinter(context);
    }
  }

  List<SaleItems> searchObjects(List<SaleItems> list, String query) {
    query = query.toLowerCase();
    return list.where((data) {
      return data.discount.toString().toLowerCase().contains(query)
          || data.paid.toString().toLowerCase().contains(query)
          || data.total.toString().toLowerCase().contains(query)
          || data.receipt.toString().toLowerCase().contains(query)
          || data.customer.toString().toLowerCase().contains(query);
    }).toList();
  }
  search(query){
    setState(() {
      searchedSaleItems=searchObjects(saleItems, query);
    });
  }

  @override
  initState() {
    fetchSaleItems();
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: kPrimaryColor),
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Row(
                      children: const [
                        Tooltip(
                          message: "Sales Window",
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 30.0,
                          ),
                        ),
                        Tooltip(
                          message: "Sales Window",
                          child: Text(
                            "Back to Sales",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    "Sales History Report",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                    flex: 10,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            height: 50,
                            child: Row(
                              children: [
                                Expanded(child: Container()),
                                Expanded(
                                    child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  decoration: const BoxDecoration(
                                      color: kPrimaryLightColor,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20))),
                                  child: DropdownButton<FilterOptions>(
                                    underline: const SizedBox(),
                                    isExpanded: true,
                                    value: filterOptions[selectedOption],
                                    iconEnabledColor: kPrimaryColor,
                                    focusColor: Colors.white,
                                    hint: const Text('Sort By'),
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedOption =
                                            filterOptions.indexOf(newValue!);
                                        if(selectedOption == 0){
                                          searchedSaleItems.sort((a, b) => b.saleDate!.compareTo(a.saleDate!));
                                        }else if(selectedOption == 1){
                                          searchedSaleItems.sort((a, b) => a.saleDate!.compareTo(b.saleDate!));
                                        }else if(selectedOption == 2){
                                         searchedSaleItems = saleItems.where((element) {
                                            return element.status == "1";
                                          }).toList();
                                        }else if(selectedOption == 3){
                                        searchedSaleItems =  saleItems.where((element) {
                                            return element.status == "0";
                                          }).toList();
                                        }

                                      });
                                    },
                                    items: filterOptions
                                        .map<DropdownMenuItem<FilterOptions>>(
                                            (value) {
                                      return DropdownMenuItem<FilterOptions>(
                                        value: value,
                                        child: Text(value.name),
                                      );
                                    }).toList(),
                                  ),
                                )),
                                Expanded(
                                    child: Container(
                                  child: TextField(
                                    onChanged: (value) {
                                      // filterRows(value);
                                      search(value);
                                    },
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.search),
                                      hintText: "Search Here",
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),

                          Expanded(child: createTable())
                        ],
                      ),
                    )),
                Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Container(
                          color: kPrimaryColor,
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: Text(
                              "Details",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Container(
                            // padding: EdgeInsets.only(left: 10, right: 10),
                            color: kPrimaryLightColor,
                            child: cartItems.isNotEmpty
                                ? ListView.separated(
                                    itemBuilder: (context, index) {
                                      var item = cartItems[index];
                                      return Container(
                                        color: index % 2 == 1
                                            ? kSecondaryColor2
                                            : kSecondaryColor,
                                        child: ListTile(
                                          title: Text(
                                              "${item.quantity} X ${item.productName}"),
                                          // subtitle: Text("${item.quantity}"),
                                          trailing:
                                              Text(item.subTotal.toString()),
                                        ),
                                      );
                                    },
                                    separatorBuilder: (context, index) {
                                      return SizedBox(
                                        height: 1,
                                        child: Container(
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                    itemCount: cartItems.length)
                                : Container(
                                  // color: Colors.red,
                                  width: double.infinity,
                                  child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                                      children:  [
                                        Icon(
                                          Icons.remove_shopping_cart,
                                          color: Colors.grey[400],
                                          size: 100,
                                        ),
                                         Text(
                                          "Click on sale to view details",
                                          style: TextStyle(
                                              fontSize: 25.0,
                                              fontWeight: FontWeight.w400,
                                          color: Colors.grey[400]
                                          ),
                                        )
                                      ],
                                    ),
                                ),
                          ),
                        ),
                        if (cartItems.isNotEmpty)
                          Container(
                            height: 250,
                            padding: const EdgeInsets.only(
                                top: 30, bottom: 30, left: 10, right: 10),
                            color: kPrimaryColor,
                            child: Column(
                              children: [
                                Expanded(
                                    child: Container(
                                  child: Column(
                                    children: [
                                      Expanded(
                                          child: Row(
                                        children: [
                                          const Expanded(
                                              child: Text(
                                            "Gross amount:",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          )),
                                          Expanded(
                                              child: Text(
                                            grossAmount,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            textAlign: TextAlign.end,
                                          )),
                                        ],
                                      )),
                                      Expanded(
                                          child: Row(
                                        children: [
                                          const Expanded(
                                              child: Text(
                                            "Discount:",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          )),
                                          Expanded(
                                              child: Text(
                                            discount,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            textAlign: TextAlign.end,
                                          )),
                                        ],
                                      )),
                                      Expanded(
                                          child: Row(
                                        children: [
                                          const Expanded(
                                              child: Text(
                                            "Total Paid:",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          )),
                                          Expanded(
                                              child: Text(
                                            totalPaid,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            textAlign: TextAlign.end,
                                          )),
                                        ],
                                      )),
                                      Expanded(
                                          child: Row(
                                        children: [
                                          const Expanded(
                                              child: Text(
                                            "Balance:",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          )),
                                          Expanded(
                                              child: Text(
                                            "${double.parse(grossAmount) - double.parse(discount) - double.parse(totalPaid)}",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            textAlign: TextAlign.end,
                                          )),
                                        ],
                                      )),
                                    ],
                                  ),
                                )),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GFButton(
                                        onPressed: () {
                                          reprintReceipt(saleId);
                                        },
                                        text: "Print Receipt",
                                        elevation: 4,
                                        textStyle: const TextStyle(
                                            color: kPrimaryColor),
                                        color: kPrimaryLightColor,
                                        icon: const Icon(
                                          Icons.print,
                                          color: kPrimaryColor,
                                        ),
                                        size: 50,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),

                                  ],
                                ),
                              ],
                            ),
                          )
                      ],
                    )),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class SaleItems {
  String? id;
  String? total;
  String? paid;
  String? discount;
  String? receipt;
  String? saleDate;
  String? status;
  String? customer;
  SaleItems(
      {this.id,
      this.total,
      this.paid,
      this.discount,
      this.receipt,
      this.saleDate,
      this.status,
      this.customer});
}

class FilterOptions {
  String name;
  String key;

  FilterOptions(this.name, this.key);
}
