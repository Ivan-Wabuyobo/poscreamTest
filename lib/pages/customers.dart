import 'package:flutter/material.dart';
import 'package:poscream/components/databaseHelper.dart';
import 'package:poscream/constants.dart';

class Customers extends StatefulWidget {
  const Customers({super.key});
  @override
  State<Customers> createState() => _CustomersState();
}

class _CustomersState extends State<Customers> {
  List customersList = [];

  fetchCustomers() {
    DatabaseHelper.instance.fCustomers().then((value) {
      customersList.clear();
      setState(() {
        for (var customer in value!) {
          customersList.add(customer);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Widget customers() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(
            bottom: 20.0,
            top: 20.0,
          ),
          margin: EdgeInsets.only(top: 10.0),
          decoration: BoxDecoration(
              color: kPrimaryColor
          ),
          child: Row(
            children: const [
              Expanded(
                  flex: 1,
                  child: Text(
                    "S/N",
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                  )),
              Expanded(
                  flex: 2,
                  child: Text("Customer Name",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text("Customer Contact",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text("Registered by",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text("Added on",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
        Expanded(
            child: ListView.builder(
                itemCount: customersList.length,
                itemBuilder: (context, index) {
                  var customer = customersList[index];
                  return Container(
                    padding: const EdgeInsets.only(
                        bottom: 10.0, top: 10.0, left: 5.0),
                    decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.grey[200] : null,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!))),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text("${index + 1}")),
                        Expanded(flex: 2, child: Text("${customer['name']}")),
                        Expanded(flex: 2, child: Text("${customer['phone']}")),
                        Expanded(
                            flex: 2, child: Text("${customer['addedBy']}")),
                        Expanded(
                            flex: 2, child: Text("${customer['addedOn']}")),
                      ],
                    ),
                  );
                }))
      ],
    );
  }

  Widget customerBalances() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(
            bottom: 20.0,
            top: 20.0,
          ),
          margin: EdgeInsets.only(top: 10.0),
          decoration: BoxDecoration(
            color: kPrimaryColor
          ),
          child: Row(
            children: const [
              Expanded(
                  flex: 1,
                  child: Text(
                    "S/N",
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                  )),
              Expanded(
                  flex: 2,
                  child: Text("Customer Name",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text("Customer Contact",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text("Balance",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
        Expanded(
            child: ListView.builder(
                itemCount: customersList
                    .where((customer) => double.parse(customer['balance']) > 0)
                    .toList()
                    .length,
                itemBuilder: (context, index) {
                  var customer = customersList
                      .where(
                          (customer) => double.parse(customer['balance']) > 0)
                      .toList()[index];
                  return Container(
                    padding: const EdgeInsets.only(
                        bottom: 10.0, top: 10.0, left: 5.0),
                    decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.grey[200] : null,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!))),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text("${index + 1}")),
                        Expanded(flex: 2, child: Text("${customer['name']}")),
                        Expanded(flex: 2, child: Text("${customer['phone']}")),
                        Expanded(
                            flex: 2, child: Text("${customer['balance']}")),
                      ],
                    ),
                  );
                }))
      ],
    );
  }

  Widget customerAdvances() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(
            bottom: 20.0,
            top: 20.0,
          ),
          margin: EdgeInsets.only(top: 10.0),
          decoration: BoxDecoration(
            color: kPrimaryColor
          ),
          child: Row(
            children: const [
              Expanded(
                  flex: 1,
                  child: Text(
                    "S/N",
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                  )),
              Expanded(
                  flex: 2,
                  child: Text("Customer Name",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text("Customer Contact",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text("Balance",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
        Expanded(
            child: ListView.builder(
                itemCount: customersList
                    .where((customer) => double.parse(customer['balance']) < 0)
                    .toList()
                    .length,
                itemBuilder: (context, index) {
                  var customer = customersList
                      .where(
                          (customer) => double.parse(customer['balance']) < 0)
                      .toList()[index];
                  return Container(
                    padding: const EdgeInsets.only(
                        bottom: 10.0, top: 10.0, left: 5.0),
                    decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.grey[200] : null,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!))),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text("${index + 1}")),
                        Expanded(flex: 2, child: Text("${customer['name']}")),
                        Expanded(flex: 2, child: Text("${customer['phone']}")),
                        Expanded(
                            flex: 2, child: Text("${customer['balance']}")),
                      ],
                    ),
                  );
                }))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabPages = <Widget>[
      Center(child: customers()),
      Center(
        child: customerBalances(),
      ),
      Center(
        child: customerAdvances(),
      ),
    ];

    final tabs = <Tab>[
      const Tab(
        icon: Icon(
          color: Colors.white,
          Icons.supervised_user_circle_rounded,
          size: 30.0,
        ),
        text: "Customers",
      ),
      const Tab(
        icon: Icon(
          Icons.monetization_on,
          size: 30.0,
          color: Colors.white,
        ),
        text: "Customer Balances",
      ),
      const Tab(
        icon: Icon(
          color: Colors.white,

          Icons.monetization_on,
          size: 30.0,
        ),
        text: "Customer Advances",
      ),
    ];

    return DefaultTabController(
      length: tabPages.length,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: kPrimaryColor,
          title: const Text(
            'Customer Details',
          ),
          bottom: TabBar(
              indicator:  BoxDecoration(color: Colors.grey[400], borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))),
              labelColor: Colors.white,
              indicatorColor: Colors.cyan,
              splashBorderRadius: BorderRadius.circular(10.0),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              tabs: tabs),
        ),
        body: TabBarView(
          children: tabPages,
        ),
      ),
    );
  }
}
