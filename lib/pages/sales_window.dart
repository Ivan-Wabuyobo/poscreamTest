import 'package:badges/badges.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:poscream/components/databaseHelper.dart';
import 'package:poscream/components/printing_component.dart';
import 'package:poscream/pages/login_screen.dart';
import 'package:poscream/pages/expenses.dart';
import 'package:poscream/pages/sales_history.dart';
import 'package:poscream/pages/settings.dart';
import 'package:poscream/pages/stock.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:poscream/components/components.dart';
import 'package:poscream/constants.dart';
import 'package:intl/intl.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:badges/badges.dart' as badges;
import 'package:poscream/services/api.dart';
import 'package:poscream/services/checkInternetConnection.dart';
import 'customers.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  PosPrinter printerObject = PosPrinter();
  var format = NumberFormat("#,###,###");
  var wholeSaleRetailButton = 0;
  List<ProductsAndUnits> productsAndUnits = [];

  //Business and user Details and other variables
  String token = '';
  String userName = "";
  String businessName = "";
  String? address = "";
  String businessId = '';
  String userId = '';
  String unSynchronizedSales = "0";
  var netTotal = '0';
  var customerBalances = "";
  var progressPercentage = 0.0;

  //List of cart Items on hold
  List<HoldData> holdData = [];
  String displayStringForOption(ProductsAndUnits option) {
    return "${option.productName}  (${(double.parse(option.instock.toString()) / double.parse(option.base_qty.toString())).round()}  ${option.unitName}   ${wholeSaleRetailButton == 1 && option.wholesale_unitprice != '0' ? option.wholesale_unitprice : option.sellingUnit})";
  }

  //List for the rows to display on the cart
  List<Widget> cartRows = [];
  List<CartItem> cartItems = [];

  //payment methods
  List<Map<String, dynamic>> paymentMethods = [];

  //customers
  List<Map<String, dynamic>> customers = [];

  //Sale Details
  var numberOfItems = 0;
  var cartValue = 0.0;
  bool isAmount = true;
  var setPercentageDiscount = 0.0;

  //Focus Nodes
  FocusNode enterAmountFocusNode = FocusNode();
  FocusNode searchFocusNode = FocusNode();
  FocusNode textFieldFocusNode = FocusNode();
  FocusNode searchProductFocusNode = FocusNode();

  //Controllers
  TextEditingController amountPaidController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  TextEditingController productController = TextEditingController();
  TextEditingController paymentDateController = TextEditingController();
  DropdownEditingController<Map<String, dynamic>>? customerController =
      DropdownEditingController();
  DropdownEditingController<Map<String, dynamic>>? paymentController =
      DropdownEditingController();

  double amountPaid = 0.0;

  //System Settings
  String? allowWholeSale = "";
  String? allowDiscount = "";
  String? saleHolding = "";
  String? setTotalAsAmountPaid = "";
  String? allowBackDateSales = "";
  String? allowNegativeStock = "";
  String? editSellingPrice = "";
  String? printReceipt = "";
  String? trackCustomers = "";
  String? viewGeneralSettings = "";
  String? viewReceiptSettings = "";

  @override
  initState() {
    super.initState();
    fetchBusinessAndUserDetails();
    fetchProductsAndUnits();
    fetchCartItems();
    fetchCustomers();
    internetChecker();
    countUnSynchronized();
    fetchSettings();
    fetchReceiptSettings();
    discountController.text="0";
    DatabaseHelper.instance.fetchHoldCartItems().then((value) {
      setState(() {
        holdData = value;
      });
      setState(() {
        fetchPaymentMethods();
        paymentDateController.text = DateTime.now().toString().split(' ')[0];
      });
    });

  }
  //Sale synchronizer
  void internetChecker() async {
    if (int.parse(unSynchronizedSales) > 0) {
      Future<bool> internetCheck =
          CheckInternetConnection().checkInternetConnectivity();
      if (await internetCheck) {
        DatabaseHelper.instance.batchSynchronizer().then((value) {
          setState(() {
            fetchServerProducts(token).then((value) {
              fetchProductsAndUnits();
              fetchServerCustomers(token).then((value) {
                fetchCustomers();
              });
            });
          });
          countUnSynchronized();
          Future.delayed(const Duration(seconds: 5), () {
            internetChecker();
          });
        });
      } else {
        countUnSynchronized();
        Future.delayed(const Duration(seconds: 5), () {
          internetChecker();
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 5), () {
        internetChecker();
      });
    }
  }

  void countUnSynchronized() {
    setState(() {
      DatabaseHelper.instance.countUnSynchronized().then((value) {
        unSynchronizedSales = value.toString();
      });
    });
  }

  buildCustomer() {
    return Column(
      children: [
        Container(
          // margin: const EdgeInsets.only(left: 5, right: 5),
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Colors.white),
          child: Row(
            children: [
              Expanded(
                flex: 12,
                child: DropdownFormField<Map<String, dynamic>>(
                  controller: customerController,
                  decoration: InputDecoration(
                      fillColor: Colors.white,
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10)),
                      ),
                      suffixIcon: customerController?.value == null
                          ? const Icon(Icons.arrow_drop_down)
                          : InkWell(
                              onTap: () {
                                setState(() {
                                  customerController?.value?.clear();
                                  customerController?.value = null;
                                  customerBalances = "";
                                  fetchCustomers();
                                });
                              },
                              child: const Icon(Icons.close_rounded)),
                      hintText: "Select Customer"),
                  onChanged: (dynamic customer) {
                    setState(() {
                      customerBalances = customer['balance'];
                    });
                  },
                  displayItemFn: (dynamic item) => Text(
                    (item ?? {})['name'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  findFn: (dynamic str) async => customers,
                  selectedFn: (dynamic item1, dynamic item2) {
                    if (item1 != null && item2 != null) {
                      return item1['name'] == item2['name'];
                    }
                    return false;
                  },
                  filterFn: (dynamic item, str) =>
                      item['name'].toLowerCase().indexOf(str.toLowerCase()) >=
                      0,
                  dropdownItemFn: (dynamic item, int position, bool focused,
                          bool selected, Function() onTap) =>
                      ListTile(
                    title: Text(item['name'] ?? ""),
                    tileColor: focused
                        ? const Color.fromARGB(20, 0, 0, 0)
                        : Colors.transparent,
                    onTap: onTap,
                  ),
                ),
              ),
              Expanded(
                  flex: 3,
                  child: IconButton(
                    onPressed: () {
                      addCustomer(context, token);
                    },
                    icon: const Icon(Icons.add_circle),
                  ))
            ],
          ),
        )
      ],
    );
  }

  void addCustomer(BuildContext context, token) {
    TextEditingController customerNameController = TextEditingController();
    TextEditingController phoneNumberController = TextEditingController();
    GlobalKey<FormState> customerFormerKey = GlobalKey<FormState>();
    FocusNode customerNameFocusNode = FocusNode();
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: StatefulBuilder(builder: (context, setState) {
            customerNameFocusNode.requestFocus();
            return CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.enter): () {},
              },
              child: Container(
                padding: const EdgeInsets.all(20.0),
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text("Add Customer")),
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
                    Form(
                        key: customerFormerKey,
                        child: Column(children: [
                          TextFormField(
                            focusNode: customerNameFocusNode,
                            validator: (value) {
                              if (value!.trim().isEmpty) {
                                return "Please add customer details";
                              }
                              return null;
                            },
                            controller: customerNameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Customer Name",
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            controller: phoneNumberController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Phone Number",
                            ),
                          )
                        ])),
                    Row(
                      children: [
                        Expanded(
                            child: ElevatedButton(
                          onPressed: () async {
                            if (customerFormerKey.currentState!.validate()) {
                              setState(() {
                                isLoading = true;
                              });
                              var data = {
                                'name': customerNameController.text,
                                "contact": phoneNumberController.text
                              };
                              await Requests.addCustomer(token, data)
                                  .then((value) async {
                                if (value == 'success') {
                                  await fetchServerCustomers(token)
                                      .then((value) {
                                    setState(() {
                                      fetchCustomers();
                                      isLoading = false;
                                      customerNameController.clear();
                                      phoneNumberController.clear();
                                    });
                                  });
                                  if (context.mounted) {
                                    alertToast(context,
                                        title: "SUCCESS",
                                        message:
                                            "Customer was registered successfully",
                                        type: "success");
                                  }
                                } else {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  fetchCustomers();
                                  alertToast(context,
                                      title: "oops Error!",
                                      message:
                                          "Unable to register customer, please try again");
                                }
                              });
                            }
                          },
                          child: isLoading
                              ? const CupertinoActivityIndicator(
                                  radius:
                                      20, // Sets the radius of the progress indicator
                                  animating: true,
                                  color: Colors.white
                                  // Controls whether the progress indicator is animating or not
                                  )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.save,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 5.0),
                                    Text("Save Customer"),
                                  ],
                                ),
                        ))
                      ],
                    )
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  _buildPaymentOption() {
    return Column(
      children: [
        Container(
          // margin: const EdgeInsets.only(top: 0, left: 5, right: 5),
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Colors.white),
          child: DropdownFormField<Map<String, dynamic>>(
            controller: paymentController,
            emptyActionText: "",
            onEmptyActionPressed: () async {},
            decoration: const InputDecoration(
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10)),
                ),
                suffixIcon: Icon(Icons.arrow_drop_down),
                hintText: "Select Payment Method"),
            onChanged: (dynamic str) {},
            displayItemFn: (dynamic item) => Text(
              (item ?? {})['name'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            findFn: (dynamic str) async => paymentMethods,
            selectedFn: (dynamic item1, dynamic item2) {
              if (item1 != null && item2 != null) {
                return item1['name'] == item2['name'];
              }
              return false;
            },
            filterFn: (dynamic item, str) =>
                item['name'].toLowerCase().indexOf(str.toLowerCase()) >= 0,
            dropdownItemFn: (dynamic item, int position, bool focused,
                    bool selected, Function() onTap) =>
                ListTile(
              title: Text(item['name']),
              tileColor: focused
                  ? const Color.fromARGB(20, 0, 0, 0)
                  : Colors.transparent,
              onTap: onTap,
            ),
          ),
        )
      ],
    );
  }

  void showDiscount(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          TextEditingController discount = TextEditingController();
          FocusNode discountFocusNode = FocusNode();
          return StatefulBuilder(builder: (context, setState) {
            discountFocusNode.requestFocus();
            return AlertDialog(
              title: const Center(child: Text("Give a sale discount")),
              content: Container(
                constraints: BoxConstraints(
                  minHeight: screenHeight * 0.2,
                  minWidth: screenWidth * 0.25,
                  maxWidth: screenWidth * 0.25,
                  maxHeight: screenHeight * 0.2,
                ),
                child: Column(
                  children: [
                    Expanded(
                        child: Center(
                      child: ToggleSwitch(
                        minWidth: 120.0,
                        initialLabelIndex: isAmount ? 0 : 1,
                        cornerRadius: 20.0,
                        activeFgColor: Colors.white,
                        inactiveBgColor: Colors.grey,
                        inactiveFgColor: Colors.white,
                        totalSwitches: 2,
                        labels: const ['Amount', 'Percentage'],
                        icons: const [
                          FontAwesomeIcons.moneyBill,
                          FontAwesomeIcons.percent
                        ],
                        activeBgColors: [
                          const [Colors.blue],
                          [Theme.of(context).primaryColor]
                        ],
                        onToggle: (index) {
                          if (index == 0) {
                            setState(() {
                              isAmount = true;
                            });
                          } else {
                            setState(() {
                              isAmount = false;
                            });
                          }
                        },
                      ),
                    )),
                    Expanded(
                      child: Container(
                        child: TextField(
                          focusNode: discountFocusNode,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            fontSize: 18.0,
                            color: const Color(0xFF151624),
                          ),
                          controller: discount,
                          onChanged: (value) {
                            if (!isAmount) {
                              if(value.isEmpty){
                                discountController.text="0";
                              }else {
                                setPercentageDiscount =
                                    double.parse(value.replaceAll(',', ''));
                                discountController.text =
                                    (cartValue * (int.parse(value) / 100))
                                        .toString();
                              }
                            } else {
                              if(value.isEmpty){
                                discountController.text="0";
                              }else {
                                discountController.text = discount.text;
                              }
                            }
                            rebuildContext();
                          },
                          maxLines: 1,
                          // maxLength: is_amount? 12 : 5,
                          inputFormatters: [
                            ThousandsFormatter(allowFraction: true)
                          ],
                          cursorColor: const Color(0xFF151624),
                          decoration: InputDecoration(
                            labelText: isAmount
                                ? 'Enter Amount'
                                : 'Enter Discount in %',
                            labelStyle: GoogleFonts.inter(
                              fontSize: 14.0,
                              color: const Color(0xFFABB3BB),
                              height: 1.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              actions: <Widget>[
                Row(
                  children: [
                    Expanded(
                        child: Card(
                      color: kPrimaryColor,
                      elevation:
                          4, // Controls the elevation of the card to give it a raised appearance
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8), // Sets the border radius of the card to make it look rounded
                      ),
                      child: InkWell(
                        onTap: () {
                          // Add your button press logic here
                          Navigator.of(context).pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )),
                    Expanded(
                      child: Card(
                        color: darkColor,
                        elevation:
                            4, // Controls the elevation of the card to give it a raised appearance
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8), // Sets the border radius of the card to make it look rounded
                        ),
                        child: InkWell(
                          onTap: () {
                            // Add your button press logic here
                            Navigator.of(context).pop();
                            rebuildContext();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Confirm',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            );
          });
        });
  }

  //fetch user and business details
  void fetchBusinessAndUserDetails() {
    DatabaseHelper.instance.fetchBusinessDetails().then((value) {
      var data = value![0];
      setState(() {
        token = data['token'];
        userName = data['username'];
        businessName = data['businessName'];
        address = data['branchAddress'];
        editSellingPrice = data["editSellingPrice"];
        viewGeneralSettings = data["viewGeneralSettings"];
        viewReceiptSettings = data["viewReceiptSettings"];
      });
    });
  }

  //Fetch products plus their units
  void fetchProductsAndUnits() async {
    await DatabaseHelper.instance.fetchProductsAndUnits().then((value) {
      productsAndUnits.clear();
      setState(() {
        for (var element in value!) {
          productsAndUnits.add(ProductsAndUnits(
            element['id'].toString(),
            element['product_id'].toString(),
            element['item_id'].toString(),
            element['productName'].toString(),
            element['product_category'],
            element['productUnitName'],
            element['minimum'].toString(),
            element['instock'].toString(),
            element['selling'].toString(),
            element['type'].toString(),
            element['unitReserve'].toString(),
            element['vat'].toString(),
            element['code'] ?? "",
            element['buying_price'].toString(),
            "${element['productName']} (${element['unitName']})",
            element['unit_server_id'],
            element['product'].toString(),
            element['unitId'],
            element['unitName'],
            element['unitSymbol'],
            element['is_base'],
            element['base_qty'],
            element['product_code'],
            element['unitSelling'],
            element['reserve'],
            element['wholesale_unitprice'],
            element['wholesale_reserveprice'],
          ));
        }
      });
    });
  }

  //Fetch items in cart
  void fetchCartItems() {
    DatabaseHelper.instance.fetchCartItems().then((value) {
      setState(() {
        numberOfItems = value!.length;
      });
      cartRows.clear();
      cartRows.clear();
      cartItems.clear();
      var sn = 0;
      cartValue = 0;
      for (var element in value!) {
        var stock = productsAndUnits.firstWhere((product) {
          return product.unitServerId == element['unit'];
        });
        var currentStock = element['quantity'];
        var previousStock = currentStock;
        sn = sn + 1;
        setState(() {
          cartValue =
              cartValue + double.parse(element['totalPrice'].toString());
          cartRows.add(Container(
            padding: const EdgeInsets.only(
                top: 5.0, bottom: 5.0, left: 10.0, right: 10),
            decoration: BoxDecoration(
                color: sn % 2 != 0 ? kPrimaryLightColor : Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
            child: Row(
              children: [
                Expanded(flex: 1, child: Text('$sn')),
                Expanded(flex: 5, child: Text('${element['productName']}')),
                Expanded(
                    flex: 2,
                    child: TextFormField(
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(0)),
                            borderSide: BorderSide.none,
                          )),
                      onChanged: (value) {
                        if (value.trim().isNotEmpty && value != '0') {
                          if (allowNegativeStock == "0" &&
                              double.parse(value) >
                                  double.parse(stock.instock)) {
                           alertToast(context,
                                message:
                                    "Quantity entered \nexceeds the available system stock",
                                title: "WARNING");
                            currentStock = previousStock;
                          } else {
                            currentStock = value;
                            previousStock = currentStock;
                            var totalPrice = double.parse(
                                    element['sellingPrice'].toString()) *
                                double.parse(value);
                            DatabaseHelper.instance
                                .updateCart(
                                    id: element['id'],
                                    quantity: value,
                                    totalPrice: totalPrice.toString())
                                .then((value) {
                              setState(() {
                                fetchCartItems();
                              });
                            });
                          }
                        }
                      },
                      controller: RightCursorTextEditingController()
                        ..text = "$currentStock",
                    )),
                const SizedBox(
                  width: 5.0,
                ),
                Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: RightCursorTextEditingController()
                        ..text = format.format(
                            int.parse(element['sellingPrice'].toString())),
                      enabled: editSellingPrice == "1" ? true : false,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(0)),
                            borderSide: BorderSide.none,
                          )),
                      inputFormatters: [
                        CurrencyTextInputFormatter(decimalDigits: 0, name: '')
                      ],
                      onChanged: (value) {
                        var totalPrice =
                            double.parse(value.replaceAll(',', '')) *
                                double.parse(element['quantity']);
                        if (value.trim().isNotEmpty && value != '0') {
                          DatabaseHelper.instance
                              .updateCart(
                                  id: element['id'],
                                  sellingPrice: value.replaceAll(',', ''),
                                  totalPrice: totalPrice.toString())
                              .then((value) {
                            setState(() {
                              fetchCartItems();
                            });
                          });
                        }
                      },
                    )),
                const SizedBox(
                  width: 5.0,
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    format
                        .format(double.parse(element['totalPrice'].toString())),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () {
                        DatabaseHelper.instance
                            .removeFromCart(element['id'])
                            .then((value) {
                          setState(() {
                            fetchCartItems();
                            calculateNetValue();
                          });
                        });
                      },
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Tooltip(
                              preferBelow: false,
                              message: "Remove product",
                              child: Icon(
                                Icons.delete_forever,
                                color: Colors.redAccent,
                              ),
                            ),
                          ]),
                    ))
              ],
            ),
          ));
          cartItems.add(CartItem(
              productName: element['productName'],
              quantity: element['quantity'],
              subTotal: element['totalPrice'],
              price: element['sellingPrice']));
        });
      }
      calculateNetValue();
    });
  }

  //Fetch payment methods from the local database
  void fetchPaymentMethods() {
    DatabaseHelper.instance.fetchPaymentMethods().then((value) {
      paymentMethods.clear();
       for (var element in value) {
         if (element['isDefault'] == '1') {
           paymentController?.value = {
             'name': element['name'].toString(),
             "id": element['payId'].toString()
           };
         }
         paymentMethods.add({
           'name': element['name'].toString(),
           "id": element['payId'].toString()
         });
       }
    });
  }

  //Fetch customers from the The local database
  void fetchCustomers() async {
    await DatabaseHelper.instance.fetchCustomers().then((value) {
      setState(() {
        customers = value;
      });
    });
  }

  //cartTable
  Widget cartTable() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.only(
              top: 10.0, bottom: 10.0, left: 10, right: 10),
          decoration: BoxDecoration(
              color: kPrimaryColor, borderRadius: BorderRadius.circular(5.0)),
          child: Row(
            children: const [
              Expanded(
                  flex: 1,
                  child: Text(
                    '#',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: kPrimaryLightColor),
                  )),
              Expanded(
                  flex: 5,
                  child: Text('Item/Service',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          color: kPrimaryLightColor))),
              Expanded(
                  flex: 2,
                  child: Text('Quantity',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          color: kPrimaryLightColor))),
              Expanded(
                  flex: 2,
                  child: Text('Rate',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          color: kPrimaryLightColor))),
              Expanded(
                  flex: 2,
                  child: Text('Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          color: kPrimaryLightColor))),
              Expanded(
                  flex: 1,
                  child: Text("",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          color: kPrimaryLightColor)))
            ],
          ),
        ),
        Expanded(
          child: cartRows.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_shopping_cart,
                      color: Colors.grey[300],
                      size: 200,
                    ),
                    Text(
                      "Add items to cart",
                      style: TextStyle(
                          fontSize: 50.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[300]!),
                    )
                  ],
                )
              : ListView.builder(
                  itemCount: cartRows.length,
                  itemBuilder: (context, index) {
                    return cartRows[index];
                  }),
        )
      ],
    );
  }

  Widget searchProducts() {
    return Container(
      alignment: Alignment.center,
      child: RawAutocomplete<ProductsAndUnits>(
        focusNode: searchProductFocusNode,
        textEditingController: productController,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            return const Iterable<ProductsAndUnits>.empty();
          }
          return productsAndUnits
              .where((element) =>
                  element.productName.toString().toLowerCase().contains(
                      textEditingValue.text.toString().toLowerCase()) ||
                  element.product_code
                      .toString()
                      .contains(textEditingValue.text.toString()) ||
                  element.code
                      .toString()
                      .contains(textEditingValue.text.toString()))
              .toList();
        },
        displayStringForOption: displayStringForOption,
        onSelected: (value) {
          setState(() {});
          if (allowNegativeStock == "0" && double.parse(value.instock) < 0) {
            productController.clear();
            alertToast(context,
                message:
                    "This item is out of stock,\nPlease restock the product to sale it.",
                title: "Out of Stock");
          } else {
            var cartData = {
              'productName': "${value.productName} (${value.unitSymbol})",
              'quantity': 1,
              'quantityTaken': 1,
              'unitName': value.unitName,
              'sellingPrice':
                  wholeSaleRetailButton == 1 && value.wholesale_unitprice != '0'
                      ? value.wholesale_unitprice
                      : value.sellingUnit,
              'totalPrice':
                  wholeSaleRetailButton == 1 && value.wholesale_unitprice != '0'
                      ? value.wholesale_unitprice
                      : value.sellingUnit,
              'product': value.product_id,
              'type': 1,
              'batch': '',
              'unit': value.unitServerId,
              'description': '',
              'saleType': wholeSaleRetailButton,
              'status': 1,
            };
            productController.clear();
            DatabaseHelper.instance
                .checkProductInCart(cartData['unit'])
                .then((value) {
              if (value.length == 0) {
                //Go ahead and a new item in cart
                DatabaseHelper.instance.addCart(cartData).then((value) {
                  fetchCartItems();
                });
              } else {
                //update the quantity if an item already exists
                var cartId = value[0]['id'];
                var quantity =
                    1 + double.parse(value[0]['quantity'].toString());
                var totalPrice =
                    double.parse(value[0]['sellingPrice'].toString()) *
                        quantity;
                DatabaseHelper.instance
                    .updateCart(
                        id: cartId,
                        quantity: quantity.toString(),
                        totalPrice: totalPrice.toString())
                    .then((value) {
                  fetchCartItems();
                });
              }
            });
          }
        },
        fieldViewBuilder: (BuildContext context, searchTextCtrl, focus,
            VoidCallback onFieldSubmitted) {
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  enabled: true,
                  autofocus: true,
                  controller: searchTextCtrl,
                  enableSuggestions: true,
                  cursorColor: kPrimaryColor,
                  textInputAction: TextInputAction.next,
                  focusNode: focus,
                  onSaved: (value) {},
                  onFieldSubmitted: (String value) {
                    onFieldSubmitted();
                    setState(() {
                      focus.requestFocus();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: "Scan Barcode or Search Product",
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(defaultPadding),
                      child: Icon(FontAwesomeIcons.barcode),
                    ),
                  ),
                ),
              )
            ],
          );
        },
        optionsViewBuilder: (BuildContext context,
            AutocompleteOnSelected<ProductsAndUnits> onSelected,
            Iterable<ProductsAndUnits> options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: SizedBox(
                height: 200.0,
                child: RawScrollbar(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final bool highlight =
                          AutocompleteHighlightedOption.of(context) == index;
                      if (highlight) {
                        SchedulerBinding.instance!
                            .addPostFrameCallback((Duration timeStamp) {
                          Scrollable.ensureVisible(context, alignment: 0.5);
                        });
                      }
                      final ProductsAndUnits option = options.elementAt(index);
                      return GestureDetector(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Builder(builder: (BuildContext context) {
                          final bool highlight =
                              AutocompleteHighlightedOption.of(context) ==
                                  index;
                          if (highlight) {
                            SchedulerBinding.instance
                                .addPostFrameCallback((Duration timeStamp) {
                              Scrollable.ensureVisible(context, alignment: 0.5);
                            });
                          }
                          return Container(
                            color:
                                highlight ? Theme.of(context).focusColor : null,
                            padding: const EdgeInsets.all(16.0),
                            child: Text(displayStringForOption(option)),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  //rebuild context on confirm discount // calls the setState from the discount dialog
  void rebuildContext() {
    setState(() {
      calculateNetValue();
    });
  }

  void holdCartItems() {
    TextEditingController identificationController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: StatefulBuilder(builder: (context, setState) {
            GlobalKey<FormState> holdFormKey = GlobalKey<FormState>();

            return Container(
              padding: const EdgeInsets.all(20.0),
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.height * 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Identify Order",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20.0),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: Colors.red[900],
                        ),
                      ),
                    ],
                  ),
                  Form(
                    key: holdFormKey,
                    child: TextFormField(
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return "Please provide an identification";
                        } else if (holdData.any(
                            (element) => element.description == value.trim())) {
                          return "This identifier ($value) already exists";
                        }
                        return null;
                      },
                      controller: identificationController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Identification"),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: ElevatedButton(
                        onPressed: () async {
                          if (holdFormKey.currentState!.validate()) {
                            await DatabaseHelper.instance
                                .cartHold(identificationController.text)
                                .then((value) async {
                              discountController.clear();
                              amountPaidController.text = '0.0';
                              await DatabaseHelper.instance
                                  .fetchHoldCartItems()
                                  .then((value) {
                                setState(() {
                                  holdData = value;
                                  cartRows.clear();
                                  rebuildContext();
                                });
                              });
                            });
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text("Proceed"),
                      ))
                    ],
                  )
                ],
              ),
            );
          }),
        );
      },
    );
  }

  //Model that shows items in hold
  void unHoldCartItems() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: kPrimaryLightColor,
          child: StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                      decoration: const BoxDecoration(
                        color: kPrimaryColor,
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                              flex: 1,
                              child: Text(
                                'S/N',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                    color: Colors.white),
                              )),
                          Expanded(
                              flex: 2,
                              child: Text('Description',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                      color: Colors.white))),
                          Expanded(
                              flex: 1,
                              child: Text("Date",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                      color: Colors.white))),
                          Expanded(
                              flex: 1,
                              child: Text("Items",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                      color: Colors.white))),
                          Expanded(
                              flex: 1,
                              child: Text("Action",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                      color: Colors.white)))
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: holdData.length,
                        itemBuilder: (context, index) {
                          var data = holdData[index];
                          return Container(
                            padding:
                                const EdgeInsets.only(top: 10.0, left: 10.0),
                            decoration: BoxDecoration(
                                color: index % 2 == 0 ? Colors.grey[200] : null,
                                border: Border(
                                    bottom:
                                        BorderSide(color: Colors.grey[400]!))),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text('${index + 1}')),
                                Expanded(
                                    flex: 2,
                                    child: Text('${data.description}')),
                                Expanded(flex: 1, child: Text("${data.date}")),
                                Expanded(
                                    flex: 1,
                                    child: Text("${data.cartItems?.length}")),
                                Expanded(
                                    flex: 1,
                                    child: PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Color(0xffe27d41),
                                      ),
                                      onSelected: (String value) {
                                        if (value == "1") {
                                          //un hold items into the cart
                                          DatabaseHelper.instance
                                              .fetchCartItems()
                                              .then((value) async {
                                            if (value!.isEmpty) {
                                              await DatabaseHelper.instance
                                                  .unHoldCartItems(data.id)
                                                  .then((value) {
                                                fetchCartItems();
                                                DatabaseHelper.instance
                                                    .fetchHoldCartItems()
                                                    .then((value) {
                                                  setState(() {
                                                    holdData = value;
                                                    Navigator.pop(context);
                                                  });
                                                });
                                              });
                                            } else {
                                              alertToast(context,
                                                  title: "oops warning!!",
                                                  message:
                                                      "First process the order in cart and continue.");
                                            }
                                          });
                                        } else if (value == "2") {
                                          if (printerObject.isConnected) {
                                            var invoiceData = {
                                              "cartItems": data.cartItems,
                                            };
                                            printerObject
                                                .printInvoice(invoiceData);
                                          } else {
                                            printerObject
                                                .selectPrinter(context);
                                          }
                                        } else if (value == "3") {
                                          DatabaseHelper.instance
                                              .deleteHoldItem(data.id)
                                              .then((value) {
                                            DatabaseHelper.instance
                                                .fetchHoldCartItems()
                                                .then((value) {
                                              setState(() {
                                                holdData = value;
                                              });
                                              rebuildContext();
                                            });
                                          });
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return <PopupMenuEntry<String>>[
                                          PopupMenuItem<String>(
                                            value: '1',
                                            child: Row(
                                              children: const [
                                                Icon(Icons.refresh,
                                                    color: Colors.blueAccent),
                                                Text('UnHold'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: '2',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.print,
                                                  color: Colors.amber[900],
                                                ),
                                                const Text('Print'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: '3',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete_outline_outlined,
                                                  color: Colors.red[900],
                                                ),
                                                const Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        ];
                                      },
                                    )),
                              ],
                            ),
                          );
                        }),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  void saveSales(bool shouldPrint) {
    //Generating a receipt number
    String saleDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    var currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    var receiptNumber = "$businessId$userId$currentTimeStamp";

    if (amountPaid >= double.parse(netTotal.replaceAll(',', '')) ||
        customerController != null) {
      //save the sale into the saleTable
      var saleDetails = {
        'paid': amountPaid,
        'total': cartValue,
        'discount': discountController.text.trim().isEmpty
            ? '0'
            : discountController.text,
        'customer': customerController?.value?['customerId'] ?? "",
        'saleDate':
            allowBackDateSales == "1" ? paymentDateController.text : saleDate,
        'mode': paymentController!.value?["id"],
        'pickingDate': '',
        'typeStatus': '1',
        'balance': '0',
        'transactionStatus': '2',
        'userId': userId,
        'customerName': customerController?.value?['name'] ?? "",
        'customerContact': '',
        'receipt': receiptNumber,
        'status': '0'
      };

      if (shouldPrint && cartRows.isNotEmpty) {
        if (printerObject.isConnected) {
          DatabaseHelper.instance.addSale(saleDetails).then((value) async {
            cartRows.clear();
            var saleData = {
              "saleDate": saleDate,
              "receipt": receiptNumber,
              "paid": amountPaidController.text,
              "total": cartValue,
              "netTotal": netTotal,
              "discount": discountController.text.trim().isEmpty
                  ? '0'
                  : discountController.text,
              "cartItems": cartItems,
              "customer": customerController?.value?['name']?.name ?? "N/A",
            };

            await printerObject.printReceipt(saleData);

            setState(() {
              calculateNetValue();
              discountController.clear();
              amountPaidController.clear();
              cartRows.clear();
              amountPaid = 0.0;
              fetchCartItems();
              setPercentageDiscount = 0.0;
              customerController?.value?.clear();
              customerBalances = "";
            });
            countUnSynchronized();
          });
        } else {
          printerObject.selectPrinter(context);
        }
      } else if (cartRows.isNotEmpty) {
        cartRows.clear();
        DatabaseHelper.instance.addSale(saleDetails).then((value) {
          setState(() {
            calculateNetValue();
            cartValue = 0;
            discountController.clear();
            amountPaidController.clear();
            cartRows.clear();
            amountPaid = 0.0;
            customerController?.value?.clear();
            setPercentageDiscount = 0.0;
            customerBalances = "";
          });
          countUnSynchronized();
          rebuildContext();
        });
      }
    } else {
      alertToast(context,
          title: "Credit Sale",
          message:
              "Amount paid is less, if it is a credit sale please select a customer to continue");
    }
  }

  void calculateNetValue() {
    if (isAmount) {
      netTotal = discountController.text.isEmpty
          ? format.format(cartValue)
          : format.format((cartValue -
              (double.parse(discountController.text.replaceAll(',', '')))));
      if (setTotalAsAmountPaid == "1") {
        amountPaidController.text = netTotal.toString();
        amountPaid =
            double.parse(amountPaidController.text.replaceAll(',', ''));
      }
    } else {
      discountController.text =
          (cartValue * setPercentageDiscount / 100).toString();
      netTotal = discountController.text.isEmpty
          ? format.format(cartValue)
          : format.format((cartValue -
              (double.parse(discountController.text.replaceAll(',', '')))));
      if (setTotalAsAmountPaid == "1") {
        amountPaidController.text = netTotal.toString();
        amountPaid =
            double.parse(amountPaidController.text.replaceAll(',', ''));
      }
    }
  }

  fetchSettings() {
    DatabaseHelper.instance.fetchSettings().then((settings) {
      for (var setting in settings) {
        setState(() {
          allowWholeSale = setting['allowWholesale'];
          allowDiscount = setting['saleDiscount'];
          saleHolding = setting['saleHolding'];
          setTotalAsAmountPaid = setting["setTotalAsPaid"];
          allowBackDateSales = setting["backDateSales"];
          allowNegativeStock = setting["allowNegativeStock"];
          trackCustomers = setting["trackCustomers"];
        });
      }
    });
  }

  fetchReceiptSettings() async {
    Database? db = await DatabaseHelper.instance.database;
    db?.query("receiptSettings").then((value) {
      setState(() {
        for(var setting in value){
          printReceipt = setting["printReceiptAfterSale"].toString();
        }
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.pageUp): () {
          setState(() {
            searchProductFocusNode.requestFocus();
          });
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          enterAmountFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.end): () {
          saveSales(true);
        },
        const SingleActivator(LogicalKeyboardKey.pageDown): () {
          saveSales(false);
        },
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
                flex: 1,
                child: Container(
                  color: kPrimaryColor,
                  padding: const EdgeInsets.only(right: 20, left: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 10,
                        child: Text(
                          "$businessName $address",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Expanded(
                            //   child: GFProgressBar(
                            //       padding: const EdgeInsets.only(top:20),
                            //       percentage: progressPercentage,
                            //       width:40,
                            //       radius: 30,
                            //       type: GFProgressType.circular,
                            //       backgroundColor : Colors.black26,
                            //       progressBarColor: GFColors.SUCCESS,
                            //   ),
                            // ),
                            InkWell(
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return const SalesHistory();
                                }));
                              },
                              child: badges.Badge(
                                badgeContent: Text(
                                  unSynchronizedSales,
                                  style: TextStyle(
                                      color: Colors.redAccent[400],
                                      fontWeight: FontWeight.bold),
                                ),
                                badgeStyle:
                                    const BadgeStyle(badgeColor: Colors.white),
                                child: const Icon(
                                  Icons.notifications_active,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Row(
                              children: [
                                const Icon(Icons.person_2_outlined,
                                    size: 30, color: Colors.white),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'Click to view',
                                  child: const Icon(
                                    Icons.arrow_drop_down_sharp,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onSelected: (value) async {
                                    if (value == '1') {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return Dialog(
                                            child: StatefulBuilder(
                                                builder: (context, setState) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(20.0),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.3,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.3,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: InkWell(
                                                          onTap: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: Icon(
                                                            Icons.close,
                                                            color:
                                                                Colors.red[900],
                                                          ),
                                                        )),
                                                    const Text(
                                                        "Are you sure you want to logout!!",
                                                        style: TextStyle(
                                                            fontSize: 20.0)),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                            child:
                                                                ElevatedButton(
                                                          onPressed: () async {
                                                            await DatabaseHelper
                                                                .instance
                                                                .logout()
                                                                .then((value) async {
                                                                  await DatabaseHelper.instance.deleteCart().then((b){
                                                                    Navigator.pushReplacement(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder:
                                                                                (context) {
                                                                              return const Login();
                                                                            }));
                                                                  });
                                                            });
                                                          },
                                                          child: const Text(
                                                              "Proceed"),
                                                        ))
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              );
                                            }),
                                          );
                                        },
                                      );
                                    } else if (value == "2") {
                                      var cancel = BotToast.showLoading();
                                      await fetchServerProducts(token);
                                      await fetchServerCustomers(token);
                                      await fetchServerSettings(token);
                                      await fetchServerPaymentMethods(token);
                                      await fetchServerReceiptSettings(token);
                                      cancel();
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return [
                                      PopupMenuItem<String>(
                                        value: '1',
                                        child: Row(
                                          children: const [
                                            Icon(Icons.login_outlined,
                                                color: Colors.redAccent),
                                            SizedBox(
                                              width: 5.0,
                                            ),
                                            Text('LOGOUT'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: '2',
                                        child: Row(
                                          children: const [
                                            Icon(Icons.sync_outlined,
                                                color: Colors.greenAccent),
                                            SizedBox(
                                              width: 5.0,
                                            ),
                                            Text('SYNC'),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )),
            Expanded(
                flex: 15,
                child: Row(
                  children: [
                    Expanded(
                        flex: 13,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                allowWholeSale == "1"
                                    ? Expanded(
                                        flex: 4,
                                        child: Center(
                                          child: ToggleSwitch(
                                            minWidth: 120.0,
                                            initialLabelIndex:
                                                wholeSaleRetailButton,
                                            cornerRadius: 20.0,
                                            activeFgColor: Colors.white,
                                            inactiveBgColor: Colors.grey,
                                            inactiveFgColor: Colors.white,
                                            totalSwitches: 2,
                                            labels: const [
                                              'Retail',
                                              'Wholesale'
                                            ],
                                            icons: const [
                                              CupertinoIcons.cart,
                                              FontAwesomeIcons.box
                                            ],
                                            activeBgColors: [
                                              [kPrimaryColor],
                                              [Theme.of(context).primaryColor]
                                            ],
                                            onToggle: (index) {
                                              if (index == 0) {
                                                setState(() {
                                                  wholeSaleRetailButton = 0;
                                                });
                                              } else {
                                                setState(() {
                                                  wholeSaleRetailButton = 1;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                                Expanded(flex: 10, child: searchProducts()),
                                const SizedBox(
                                  width: 20,
                                )
                              ],
                            ),
                            Expanded(
                                child: Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        25, 15, 25, 10),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                    ),
                                    child: cartTable() //table goes here
                                    ))
                          ],
                        )),
                    Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          color: kPrimaryLightColor,
                          child: Column(
                            children: [
                              Expanded(
                                  flex: 12,
                                  child: ListView(
                                    // crossAxisAlignment:
                                    //     CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Payment Options",
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                          _buildPaymentOption(),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          if(trackCustomers == "1")
                                          const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Customers",
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                          if(trackCustomers == "1")
                                            buildCustomer(),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          if (customerBalances.isNotEmpty)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      "Balance:",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: double.parse(
                                                                      customerBalances) <
                                                                  0
                                                              ? Colors.red
                                                              : Colors
                                                                  .blueAccent),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      "${format.format(double.parse(customerBalances))}",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: double.parse(
                                                                      customerBalances) <
                                                                  0
                                                              ? Colors.red
                                                              : Colors
                                                                  .blueAccent),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          // child: Text("Balance: $customerBalances")),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          allowDiscount == "1"
                                              ? const Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      "Give a  Discount",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontSize: 16)))
                                              : const SizedBox(),
                                          allowDiscount == "1"
                                              ? Container(
                                                  // margin: const EdgeInsets.only(
                                                  //     left: 5, right: 5),
                                                  child: InkWell(
                                                    onTap: () {
                                                      showDiscount(context);
                                                    },
                                                    child: TextField(
                                                      controller:
                                                          discountController,
                                                      enabled: false,
                                                      textAlign:
                                                          TextAlign.right,
                                                      decoration:
                                                          const InputDecoration(
                                                              hintText: "0/=",
                                                              hintStyle:
                                                                  TextStyle(
                                                                      fontSize:
                                                                          16),
                                                              fillColor:
                                                                  Colors.white,
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderRadius: BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            10)),
                                                                borderSide:
                                                                    BorderSide
                                                                        .none,
                                                              )),
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox(),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          if (allowBackDateSales == "1")
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  left: 8.0, bottom: 8.0),
                                              child: Text("Add Sale Date"),
                                            ),
                                          if (allowBackDateSales == "1")
                                            DateTimePicker(
                                              controller: paymentDateController,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime.now(),
                                              decoration: InputDecoration(
                                                  hintStyle: const TextStyle(
                                                      fontSize: 16),
                                                  fillColor: Colors.white,
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                          borderRadius:
                                                              const BorderRadius
                                                                      .all(
                                                                  Radius
                                                                      .circular(
                                                                          10)),
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                          .grey[
                                                                      200]!))),
                                            )
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                                margin: const EdgeInsets.only(
                                                    top: 10.0, bottom: 5.0),
                                                child: const Text(
                                                    "Enter Amount Received",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20.0))),
                                          ),
                                          TextField(
                                            style:
                                                const TextStyle(fontSize: 30),
                                            keyboardType: TextInputType.number,
                                            controller: amountPaidController,
                                            inputFormatters: [
                                              ThousandsFormatter()
                                            ],
                                            onChanged: (value) {
                                              if (value.isNotEmpty) {
                                                setState(() {
                                                  amountPaid = double.parse(
                                                      amountPaidController.text
                                                          .replaceAll(",", ""));
                                                });
                                              } else {
                                                setState(() {
                                                  amountPaid = 0.0;
                                                });
                                              }
                                            },
                                            focusNode: enterAmountFocusNode,
                                            textAlign: TextAlign.right,
                                            decoration: const InputDecoration(
                                                hintStyle:
                                                    TextStyle(fontSize: 16),
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                10)),
                                                    borderSide:
                                                        BorderSide.none)),
                                          ),
                                          const SizedBox(height: 25.0),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: amountPaid >
                                                            double.parse(
                                                                netTotal
                                                                    .replaceAll(
                                                                        ',',
                                                                        ''))
                                                        ? const Text("Change",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 20.0))
                                                        : const Text('Balance',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize:
                                                                    25.0)),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: amountPaid >
                                                            double.parse(
                                                                netTotal
                                                                    .replaceAll(
                                                                        ',',
                                                                        ''))
                                                        ? Text(
                                                            format.format(amountPaid -
                                                                double.parse(netTotal
                                                                    .replaceAll(
                                                                        ',',
                                                                        ''))),
                                                            style: const TextStyle(
                                                                fontSize: 25,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,

                                                                color: Colors
                                                                    .teal),
                                                          )
                                                        : Text(
                                                            format.format(double
                                                                    .parse(netTotal
                                                                        .replaceAll(
                                                                            ',',
                                                                            '')) -
                                                                amountPaid),
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,

                                                                color: Colors
                                                                        .redAccent[
                                                                    700]),
                                                          ),
                                                  ),
                                                )
                                              ]),
                                          const SizedBox(height: 25.0),
                                          const Divider(),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Expanded(
                                                      flex: 1,
                                                      child: Text(
                                                        'TOTAL',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Text(
                                                        format
                                                            .format(cartValue),
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                discountController.text
                                                        .trim()
                                                        .isNotEmpty
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              discountController.text=="0" || discountController.text.isEmpty? 'Discount(0%)':
                                                              'Discount(${((double.parse(discountController.text.replaceAll(",", "")) / cartValue) * 100).toStringAsFixed(1)}%)',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              discountController
                                                                  .text,
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : const SizedBox(),
                                                const SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      flex: 1,
                                                      child: Text(
                                                        'Net Total',
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.green[900],
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            netTotal,
                                                            textAlign:
                                                                TextAlign.right,
                                                            style: TextStyle(

                                                                fontSize: 35,
                                                                color: Colors
                                                                    .green[900],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(),
                                        ],
                                      )
                                    ],
                                  )),
                            ],
                          ),
                        )),
                  ],
                )),
            Expanded(
                flex: 2,
                child: Container(
                  color: kPrimaryLightColor,
                  child: Row(
                    children: [
                      Expanded(
                          flex: 13,
                          child: Container(
                            color: Colors.white,
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return const SalesHistory();
                                          },
                                        ),
                                      );
                                    },
                                    child: Card(
                                      color: Theme.of(context)
                                          .primaryColor, // set the background color of the card to the primary color
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Expanded(
                                            flex: 5,
                                            child: Icon(
                                              CupertinoIcons.barcode_viewfinder,
                                              size: 45,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "Sales History",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                        return const Stock();
                                      }));
                                    },
                                    child: Card(
                                      color: Theme.of(context)
                                          .primaryColor, // set the background color of the card to the primary color
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Expanded(
                                            flex: 5,
                                            child: Icon(
                                              Icons.inventory_outlined,
                                              size: 45,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "Stock",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                        return const Expenses();
                                      }));
                                    },
                                    child: Card(
                                      color: Theme.of(context)
                                          .primaryColor, // set the background color of the card to the primary color
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Expanded(
                                            flex: 5,
                                            child: Icon(
                                              CupertinoIcons.money_dollar,
                                              size: 45,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "Expenses",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if(trackCustomers == "1")
                                  Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                        return const Customers();
                                      }));
                                    },
                                    child: Card(
                                      color: Theme.of(context)
                                          .primaryColor, // set the background color of the card to the primary color
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Expanded(
                                            flex: 5,
                                            child: Icon(
                                              Icons.point_of_sale_outlined,
                                              size: 45,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "Customers",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                saleHolding == "1"
                                    ? Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            DatabaseHelper.instance
                                                .fetchCartItems()
                                                .then((value) {
                                              if (value!.isEmpty) {
                                                alertToast(context,
                                                    message:
                                                        "There are no items in cart to hold.",
                                                    title: "Empty cart");
                                              } else {
                                                holdCartItems();
                                              }
                                            });
                                          },
                                          child: Card(
                                            color: Theme.of(context)
                                                .primaryColor, // set the background color of the card to the primary color
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  CupertinoIcons
                                                      .cart_badge_plus,
                                                  size: 50,
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "Hold cart",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                               if (saleHolding == "1")
                                    Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            DatabaseHelper.instance
                                                .fetchHoldCartItems()
                                                .then((value) {
                                              if (value!.isEmpty) {
                                              alertToast(context,
                                                    title: "No items on hold",
                                                    message:
                                                        "You have not put any items on hold.");
                                              } else {
                                                unHoldCartItems();
                                              }
                                            });
                                          },
                                          child: Card(
                                            color: Theme.of(context)
                                                .primaryColor, // set the background color of the card to the primary color
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                badges.Badge(
                                                  badgeContent: Text(
                                                    '${holdData.length}',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .redAccent[400],
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  badgeStyle: const BadgeStyle(
                                                      badgeColor: Colors.white),
                                                  child: const Icon(
                                                    Icons
                                                        .shopping_cart_outlined,
                                                    color: Colors.white,
                                                    size: 45,
                                                  ),
                                                ),
                                                const Text(
                                                  "UnHold",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                if(viewGeneralSettings == "1" || viewReceiptSettings == "1")
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      // Components.settingDialog(context);
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                            return Settings();
                                          }));
                                    },
                                    child: Card(
                                      color: Theme.of(context)
                                          .primaryColor, // set the background color of the card to the primary color
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Expanded(
                                            flex: 5,
                                            child: Icon(
                                              CupertinoIcons.settings,
                                              size: 45,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "Settings",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: const BoxDecoration(
                            color:
                                kPrimaryLightColor, // Set the background color
                            // borderRadius: BorderRadius.circular(10.0), // Add rounded corners to the container
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: GFButton(
                                  onPressed: () {
                                    saveSales(false);
                                    setState(() {
                                      searchProductFocusNode.requestFocus();
                                    });
                                  },
                                  text: "Save and Exit",
                                  elevation: 4,
                                  textStyle:
                                      const TextStyle(color: Colors.white),
                                  color: kPrimaryColor,
                                  icon: const Icon(
                                    Icons.save,
                                    color: Colors.white,
                                  ),
                                  size: 50,
                                ),
                              ),
                              const SizedBox(width: 5.0),
                              if(printReceipt == "1")
                                Expanded(
                                child: GFButton(
                                  onPressed: () {
                                    saveSales(true);
                                    setState(() {
                                      searchProductFocusNode.requestFocus();
                                    });
                                  },
                                  text: "Save and Print",
                                  elevation: 4,
                                  textStyle:
                                      const TextStyle(color: Colors.white),
                                  color: kPrimaryColor,
                                  icon: const Icon(
                                    Icons.print,
                                    color: Colors.white,
                                  ),
                                  size: 50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
