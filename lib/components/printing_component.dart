import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:poscream/components/databaseHelper.dart';
import 'package:poscream/components/components.dart';
class PosPrinter {
  PosPrinter(){
    scanDevices();
    fetchBusinessDetails();
    fetchCartItems();
  }
  List<CartItem> cartItems = [];
  String businessName = "";
  String businessEmail = "";
  String userName = "";
  String businessContacts = "";
  String businessAddress = "";
  var defaultPrinterType = PrinterType.usb;
  var isConnected = false;
  var printerManager = PrinterManager.instance;
  var devices = <PrinterModel>[];
  List<int>? pendingTask;

  final ipController = TextEditingController();
  final portController = TextEditingController();
  PrinterModel? selectedPrinter;

  fetchBusinessDetails(){
    DatabaseHelper.instance.fetchBusinessDetails().then((value) {
      for(var element in value!){
        businessName = element['businessName'];
        businessEmail = element['email'] ?? "";
        userName = element['username'];
        businessContacts = "${element['businessPhone1']}/${element['businessPhone2']}";
        businessAddress = element['businessAddress'];
      }
    });
  }

  fetchCartItems(){
    cartItems.clear();
    DatabaseHelper.instance.fetchCartItems().then((value) {
      for(var item in value!){
        cartItems.add(
          CartItem(productName: item['productName'], quantity: item['quantity'], price: item['sellingPrice'], subTotal: item['totalPrice'])
        );
      }
    });
  }

  // method to scan devices
  void scanDevices() {
    devices.clear();
    printerManager.discovery(type: PrinterType.usb).listen(
      (device) {
        devices.add(PrinterModel(
          deviceName: device.name,
          address: device.address,
          vendorId: device.vendorId,
          productId: device.productId,
          typePrinter: defaultPrinterType,
        ));
      },
    );
  }


  void selectDevice(PrinterModel device) async {
    if (selectedPrinter != null) {
      if ((device.address != selectedPrinter!.address) ||
          (device.typePrinter == PrinterType.usb &&
              selectedPrinter!.vendorId != device.vendorId)) {
        await PrinterManager.instance
            .disconnect(type: selectedPrinter!.typePrinter);
      }
    }
    selectedPrinter = device;
  }


  Future printReceipt(var saleData) async {
    var balanceType = "Change";
    var balanceValue = "";
    var amountPaid = double.parse(saleData['paid'].replaceAll(",", ""));
    var netValue = double.parse(saleData['total'].toString().replaceAll(',', ''))  - double.parse(saleData['discount'].replaceAll(",", ""));
    if(amountPaid < netValue){
      balanceType = "Balance";
      balanceValue = (netValue - amountPaid).toString();
    }else{
      balanceValue = (amountPaid - netValue).toString();
    }
    List<int> bytes = [];
    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm80, profile);
    bytes += generator.setGlobalCodeTable('CP1252');
    bytes += generator.text(businessName,
        styles: const PosStyles(align: PosAlign.center, bold: true, fontType: PosFontType.fontA, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text('Location: $businessAddress',
        styles: const PosStyles(align: PosAlign.center,  fontType: PosFontType.fontB, height: PosTextSize.size2, width: PosTextSize.size1));
    bytes += generator.text('Tel: $businessContacts',
        styles: const PosStyles(align: PosAlign.center,   fontType: PosFontType.fontB, height: PosTextSize.size2, width: PosTextSize.size1));
    bytes += generator.emptyLines(1);
    bytes += generator.text('Sale receipt',
        styles: const PosStyles(align: PosAlign.center, underline: true, bold: true, height: PosTextSize.size2));
    bytes += generator.emptyLines(1);
    bytes += generator.text('Receipt No: ${saleData['receipt']}',
        styles: const PosStyles(align: PosAlign.center, ));
    bytes += generator.text('Date: ${saleData['saleDate']}',
        styles: const PosStyles(align: PosAlign.center,));
    bytes += generator.row([
      PosColumn(
          width: 7,
          text: 'Product',
          styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          width: 2,
          text: 'Amount',
          styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(
          width: 1,
          text: 'Qty',
          styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(
          width: 2,
          text: 'Total',
          styles: const PosStyles(align: PosAlign.center, bold: true)),
    ]);

    for (var item in saleData['cartItems']) {
      // sum width total column must be 12
      bytes += generator.row([
        PosColumn(
            width: 7,
            text: '${item.productName}',
            styles: const PosStyles(align: PosAlign.left)),
        PosColumn(
            width: 2,
            text: '${item.price}',
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            width: 1,
            text: '${item.quantity}',
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            width: 2,
            text: '${item.subTotal}',
            styles: const PosStyles(align: PosAlign.center)),
      ]);
    }
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          width: 6,
          text: 'Sub Total',
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          width: 6,
          text: '${saleData['total']}',
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    showDiscount ?
    bytes += generator.row([
      PosColumn(
          width: 6,
          text: 'Discount',
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(

          width: 6, text: '${saleData['discount']}', styles: const PosStyles(align: PosAlign.right)),
    ]) : null;

    bytes += generator.row([
      PosColumn(
          width: 6,
          text: 'Payable',
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          width: 6,
          text: '${double.parse(saleData['total'].toString()) - double.parse(saleData['discount'].replaceAll(",", ""))}',
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          width: 6,
          text: 'Cash Received',
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          width: 6,
          text: '${saleData['paid']}',
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          width: 6,
          text: balanceType,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          width: 6, text: balanceValue, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          width: 6,
          text: 'Customer',
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          width: 6, text: '${saleData['customer']}', styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text('Received by: $userName',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.text('Thank you for shopping with us!',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Powered by Nugsoft Technologies Ltd!',
        styles: const PosStyles(align: PosAlign.center));
    var connectedTCP = false;
    if (selectedPrinter == null) return;
    var connectPrinter = selectedPrinter!;
    switch (connectPrinter.typePrinter) {
      case PrinterType.usb:
        bytes += generator.cut();
        bytes += generator.drawer();
        bytes += generator.beep(n: 1);
        await printerManager.connect(
            type: connectPrinter.typePrinter,
            model: UsbPrinterInput(
                name: connectPrinter.deviceName,
                productId: connectPrinter.productId,
                vendorId: connectPrinter.vendorId));
        pendingTask = null;
        break;
      case PrinterType.network:
        bytes += generator.cut();
        bytes += generator.drawer();
        bytes += generator.beep(n: 1);
        connectedTCP = await printerManager.connect(
            type: connectPrinter.typePrinter,
            model: TcpPrinterInput(ipAddress: connectPrinter.address!));
        if (!connectedTCP) print(' --- please review your connection ---');
        break;
      default:
    }
    printerManager.send(type: connectPrinter.typePrinter, bytes: bytes);
  }

  Future printInvoice(var invoiceData) async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm80, profile);
    bytes += generator.setGlobalCodeTable('CP1252');
    bytes += generator.text(businessName,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(businessAddress,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Tel: $businessContacts',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(businessEmail,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Order Invoice',
        styles: const PosStyles(align: PosAlign.center, underline: true));
    bytes += generator.row([
      PosColumn(
          width: 7,
          text: 'Product',
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          width: 2,
          text: 'Amount',
          styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          width: 1,
          text: 'Qty',
          styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          width: 2,
          text: 'Total',
          styles: const PosStyles(align: PosAlign.center)),
    ]);

    double totalPrice = 0;

    for (var item in invoiceData['cartItems']) {

      totalPrice = totalPrice + double.parse(item['totalPrice']);
      // sum width total column must be 12
      bytes += generator.row([
        PosColumn(
            width: 7,
            text: '${item['productName']}',
            styles: const PosStyles(align: PosAlign.left)),
        PosColumn(
            width: 2,
            text: '${item['sellingPrice']}',
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            width: 1,
            text: '${item['quantity']}',
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            width: 2,
            text: '${item['totalPrice']}',
            styles: const PosStyles(align: PosAlign.center)),
      ]);
    }
    bytes += generator.hr(linesAfter: 1);
    bytes += generator.row([
      PosColumn(
          width: 6,
          text: 'Sub Total',
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          width: 6,
          text: '$totalPrice',
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr(linesAfter: 1);
    bytes += generator.text('Served by: $userName',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Powered by Nugsoft Technologies Ltd!',
        styles: const PosStyles(align: PosAlign.center));
    var connectedTCP = false;
    if (selectedPrinter == null) return;
    var connectPrinter = selectedPrinter!;
    switch (connectPrinter.typePrinter) {
      case PrinterType.usb:
        bytes += generator.cut();
        bytes += generator.drawer();
        bytes += generator.beep(n: 1);
        await printerManager.connect(
            type: connectPrinter.typePrinter,
            model: UsbPrinterInput(
                name: connectPrinter.deviceName,
                productId: connectPrinter.productId,
                vendorId: connectPrinter.vendorId));
        pendingTask = null;
        break;
      case PrinterType.network:
        bytes += generator.cut();
        bytes += generator.drawer();
        bytes += generator.beep(n: 1);
        connectedTCP = await printerManager.connect(
            type: connectPrinter.typePrinter,
            model: TcpPrinterInput(ipAddress: connectPrinter.address!));
        if (!connectedTCP) print(' --- please review your connection ---');
        break;
      default:
    }
    printerManager.send(type: connectPrinter.typePrinter, bytes: bytes);
  }


  connectDevice() async {
    isConnected = false;
    switch (selectedPrinter!.typePrinter) {
      case PrinterType.usb:
        await printerManager.connect(
            type: selectedPrinter!.typePrinter,
            model: UsbPrinterInput(
                name: selectedPrinter!.deviceName,
                productId: selectedPrinter!.productId,
                vendorId: selectedPrinter!.vendorId));
        isConnected = true;
        break;
      case PrinterType.network:
        await printerManager.connect(
            type: selectedPrinter!.typePrinter,
            model: TcpPrinterInput(ipAddress: selectedPrinter!.address!));
        isConnected = true;
        break;
      default:
    }
  }

  //Connect a printer
   selectPrinter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: StatefulBuilder(builder: (context, setState) {

            return Container(
              padding: const EdgeInsets.all(20.0),
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.height * 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Expanded(child:  Text("Select your printer", style: TextStyle(fontWeight: FontWeight.bold),)),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: Colors.red[900],
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<PrinterModel>(
                    value: selectedPrinter,
                    items: devices.map((PrinterModel option) {
                      return DropdownMenuItem<PrinterModel>(
                        value: option,
                        child: Text(option.deviceName.toString()),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedPrinter = newValue;
                        connectDevice();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Printer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.print,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5.0),
                                Text("Connect Printer"),
                              ],
                            ),
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
}

class PrinterModel {
  int? id;
  String? deviceName;
  String? address;
  String? port;
  String? vendorId;
  String? productId;
  bool? isBle;

  PrinterType typePrinter;
  bool? state;

  PrinterModel(
      {this.deviceName,
      this.address,
      this.port,
      this.state,
      this.vendorId,
      this.productId,
      this.typePrinter = PrinterType.bluetooth,
      this.isBle = false});
}

class CartItem{
  String? productName;
  String? quantity;
  String? subTotal;
  String? price;

  CartItem({this.productName, this.quantity, this.subTotal, this.price});
}