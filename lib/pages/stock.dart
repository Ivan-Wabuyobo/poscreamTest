import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:poscream/components/databaseHelper.dart';
import '../components/printing_component.dart';
import '../constants.dart';

class Stock extends StatefulWidget {
  const Stock({Key? key}) : super(key: key);

  @override
  State<Stock> createState() => _StockState();
}

class _StockState extends State<Stock> {
  @override
  initState() {
    fetchProducts();
    super.initState();
  }
  List<Product> products = [];
  List<Product> searchedProducts = [];
  List<CartItem> cartItems = [];
  List<String> productCategories = [];

  fetchProducts() {
    DatabaseHelper.instance.fetchProductsAndUnits().then((value) {
      products.clear();
      searchedProducts.clear();
      productCategories.clear();
      var sn = 0;
      for (var product in value!) {
        sn = sn + 1;
        setState(() {
          products.add(Product(
            id: product['id'].toString(),
            productName: product['productName'],
            stock: "${product['instock']}  ${product['unitName']}",
            buyingPrice: product['buyingPrice'],
            sellingPrice: product['unitSelling'],
            category: product['product_category'],
          ));
          productCategories.add(product['product_category']);
        });
      }
      setState(() {
        searchedProducts = products;
      });
    });
  }

  Widget createTable() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(child: Container()),
              Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0)),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchedProducts = products.where((sale) {
                            final product = sale.productName!.toLowerCase();
                            final input = value.toLowerCase();
                            return product.contains(input);
                          }).toList();
                        });
                      },
                      decoration: InputDecoration(
                          hintText: "Search here",
                          enabledBorder: OutlineInputBorder(

                              borderSide: const BorderSide(color: kPrimaryLightColor),
                              borderRadius: BorderRadius.circular(20.0)),
                          prefixIcon: const Icon(Icons.search)),
                    )),
              ),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                      // decoration: BoxDecoration(
                      //     border: Border.all(color: Colors.grey[200]!),
                      //     borderRadius: BorderRadius.circular(5.0)
                      // ),
                      child: DropdownSearch<String>(
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          showSelectedItems: true,
                          disabledItemFn: (String s) => s.startsWith('I'),
                        ),
                        items: productCategories.toSet().toList(),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            hintText: "product categories",
                          ),
                        ),
                        onChanged: (value){
                          setState(() {
                            searchedProducts = products.where((sale) {
                              final productCategory = sale.category!.toLowerCase();
                              final input = value!.toLowerCase();
                              return productCategory.contains(input);
                            }).toList();
                          });
                        },
                      ))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10.0),
          decoration: const BoxDecoration(
            color: kPrimaryColor
          ),
          child: Row(
            children: const [
              Expanded(
                  flex: 1,
                  child: Text('S/N',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text('Product Name',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text('Category',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text(
                    'Buying Price',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white),
                  )),
              Expanded(
                  flex: 2,
                  child: Text(
                    'Selling Price',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white ),
                  )),
              Expanded(
                  flex: 2,
                  child: Text(
                    'In stock',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white),
                  )),
            ],
          ),
        ),
        Expanded(
            child: ListView.builder(
                itemCount: searchedProducts.length,
                itemBuilder: (context, index) {
                  var product = searchedProducts[index];
                  var sn = 1 + index;
                  return InkWell(
                    child: Container(
                      padding: const EdgeInsets.only(
                          bottom: 10.0, top: 10.0, left: 5.0),
                      decoration: BoxDecoration(
                          color: index % 2 == 0 ? Colors.grey[200] : null,
                          border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!))),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Text(
                                '$sn',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w200),
                              )),
                          Expanded(
                              flex: 2, child: Text('${product.productName}')),
                          Expanded(flex: 2, child: Text('${product.category}')),
                          Expanded(
                              flex: 2,
                              child: Text(
                                '${product.buyingPrice}',
                              )),
                          Expanded(
                              flex: 2,
                              child: Text(
                                '${product.sellingPrice}',
                              )),
                          Expanded(
                              flex: 2,
                              child: Text(
                                '${product.stock}',
                              )),
                        ],
                      ),
                    ),
                  );
                }))
      ],
    );
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
                    onTap: (){
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
                    "Products and Stock",
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
                    child: Column(
                      children: [
                        Expanded(
                            flex: 10,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              child: createTable(),
                            )),
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

class Product {
  String? id;
  String? productName;
  String? category;
  String? buyingPrice;
  String? sellingPrice;
  String? stock;
  Product({
    this.id,
    this.productName,
    this.category,
    this.buyingPrice,
    this.sellingPrice,
    this.stock,
  });
}
