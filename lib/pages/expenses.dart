import 'package:date_time_picker/date_time_picker.dart';
import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:poscream/components/databaseHelper.dart';
import 'package:poscream/services/api.dart';
import '../components/components.dart';
import '../constants.dart';

class Expenses extends StatefulWidget {
  const Expenses({Key? key}) : super(key: key);
  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  @override
  initState() {
    fetchBusinessDetails().then((value) {
      fetchExpenses();
      fetchExpenseCategories();
    });
    fetchPaymentMethods();
    super.initState();
  }

  String token = "";
  List<Expense> expenses = [];
  List<Expense> searchedExpenses = [];
  List<String> productCategories = [];
  List<Map<String, dynamic>> expenseCategories = [];
  List<Map<String, dynamic>> paymentMethods = [];

  fetchExpenses() async {
    await Requests.fetchExpenses(token).then((value) {
      expenses.clear();
      setState(() {
        for (var expense in value) {
          expenses.add(Expense(
              id: expense['id'].toString(),
              date: expense['date'],
              amount: expense['amount'].toString(),
              category: expense['category'],
              description: expense['description'],
              user: expense['user']['names']));
        }
        searchedExpenses = expenses;
      });
    });
  }

  fetchExpenseCategories() async {
    Requests.fetchExpenseCategories(token).then((value) {
      expenseCategories.clear();
      for (var element in value) {
        expenseCategories.add({"name": element['name'], "id": element['id']});
      }
    });
  }

  expenseCategory() {
    TextEditingController expenseCategory = TextEditingController();
    bool isLoading = false;
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: StatefulBuilder(builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(20.0),
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                            child: Text(
                          "Record new Expense Category",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
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
                        child: Column(children: [
                      TextFormField(
                        controller: expenseCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Category",
                        ),
                      ),
                    ])),
                    Row(
                      children: [
                        Expanded(
                            child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });
                            var data = {
                              'name': expenseCategory.text,
                            };
                            Requests.addExpenseCategory(token, data)
                                .then((value) {

                              if (value == 'success') {
                               alertToast(context, title: "SUCCESS", message: "Expense category was successfully added!", type: "success");
                              } else {
                                alertToast(context, title: "ERROR", message: "Unable to add expense category, please try again");
                              }
                            });
                          },
                          child: isLoading
                              ? CupertinoActivityIndicator(
                                  radius:
                                      20, // Sets the radius of the progress indicator
                                  animating: true,
                                  color: Colors.green[800]
                                  )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.save,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 5.0),
                                    Text("Save"),
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
        });
  }

  addExpense() {
    TextEditingController expenseController = TextEditingController();
    TextEditingController paymentDateController = TextEditingController();
    paymentDateController.text = DateTime.now().toString().split('')[0];
    String expenseCategory = "";
    TextEditingController expenseDescription = TextEditingController();

    bool isLoading = false;
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: StatefulBuilder(builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(20.0),
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                            child: Text(
                          "Record new Expense",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
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
                    const Divider(),
                    Form(
                        child: Column(children: [
                      DropdownFormField<Map<String, dynamic>>(
                        emptyActionText: "",
                        onEmptyActionPressed: () async {},
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                            labelText: "Expense Category"),
                        onChanged: (dynamic str) {
                          expenseCategory = str['id'].toString();
                        },
                        displayItemFn: (dynamic item) => Text(
                          (item ?? {})['name'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                        findFn: (dynamic str) async => expenseCategories,
                        selectedFn: (dynamic item1, dynamic item2) {
                          if (item1 != null && item2 != null) {
                            return item1['name'] == item2['name'];
                          }
                          return false;
                        },
                        filterFn: (dynamic item, str) =>
                            item['name']
                                .toLowerCase()
                                .indexOf(str.toLowerCase()) >=
                            0,
                        dropdownItemFn: (dynamic item,
                                int position,
                                bool focused,
                                bool selected,
                                Function() onTap) =>
                            ListTile(
                          title: Text(item['name']),
                          tileColor: focused
                              ? const Color.fromARGB(20, 0, 0, 0)
                              : Colors.transparent,
                          onTap: onTap,
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      TextFormField(
                        controller: expenseController,
                        inputFormatters: [
                          ThousandsFormatter(allowFraction: true)
                        ],
                        onChanged: (value) {
                          setState(() {});
                        },
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Expense Amount",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      DateTimePicker(
                        controller: paymentDateController,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Date',
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                          Container(
                            margin: const EdgeInsets.only(top: 0, left: 5, right: 5),
                            decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                color: Colors.white),
                            child: DropdownFormField<Map<String, dynamic>>(
                              controller: DatabaseHelper.instance.paymentController,
                              emptyActionText: "",
                              onEmptyActionPressed: () async {},
                              decoration: const InputDecoration(
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomLeft: Radius.circular(10)),
                                  ),
                                  suffixIcon: Icon(Icons.arrow_drop_down),
                                  labelText: "Select Payment Method"),
                              onChanged: (dynamic str) {
                              },
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
                              item['name']
                                  .toLowerCase()
                                  .indexOf(str.toLowerCase()) >=
                                  0,
                              dropdownItemFn: (dynamic item,
                                  int position,
                                  bool focused,
                                  bool selected,
                                  Function() onTap) =>
                                  ListTile(
                                    title: Text(item['name']),
                                    tileColor: focused
                                        ? const Color.fromARGB(20, 0, 0, 0)
                                        : Colors.transparent,
                                    onTap: onTap,
                                  ),
                            ),

                            // DropDownTextField(
                            //   clearOption: true,
                            //   textFieldFocusNode: textFieldFocusNode,
                            //   searchFocusNode: searchFocusNode,
                            //   controller: DatabaseHelper.instance.paymentMethodsController,
                            //   searchAutofocus: true,
                            //   dropDownItemCount: 4,
                            //   searchShowCursor: true,
                            //   enableSearch: true,
                            //   searchKeyboardType: TextInputType.text,
                            //   textFieldDecoration: const InputDecoration(
                            //       hintText: "Payment Option",
                            //       hintStyle: TextStyle(fontSize: 16),
                            //       fillColor: Colors.white,
                            //       border: OutlineInputBorder(
                            //         borderRadius: BorderRadius.only(
                            //             topLeft: Radius.circular(10),
                            //             bottomLeft: Radius.circular(10)),
                            //         borderSide: BorderSide.none,
                            //       )),
                            //   searchDecoration: const InputDecoration(
                            //       fillColor: kPrimaryLightColor,
                            //       border: OutlineInputBorder(
                            //         borderRadius: BorderRadius.all(Radius.circular(0)),
                            //         borderSide: BorderSide.none,
                            //       )),
                            //   dropDownList: paymentMethods,
                            //   onChanged: (val) {
                            //     setState(() {
                            //       print(val.toString());
                            //       DatabaseHelper.instance.paymentMethodsController.dropDownValue =
                            //           val;
                            //     });
                            //   },
                            // ),
                          ),
                          const SizedBox(
                        height: 10.0,
                      ),
                      TextFormField(
                        controller: expenseDescription,
                        maxLines: 4,
                        minLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 2.0,
                      ),
                    ])),
                    Row(
                      children: [
                        Expanded(
                            child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });
                            var data = {
                              'amount':
                                  expenseController.text.replaceAll(',', ''),
                              'mode': DatabaseHelper
                                  .instance
                                  .paymentController?.value?['payId'],
                              'date': paymentDateController.text,
                              'category': expenseCategory,
                              'description': expenseDescription.text,
                              'transaction_status': 2
                            };

                            Requests.addExpenses(token, data).then((value) {
                              if (value == 'success') {
                                setState(() {
                                  fetchExpenses();
                                });
                                // Alert(
                                //   context: context,
                                //   type: AlertType.success,
                                //   title: "SUCCESS",
                                //   desc: "Expense was successfully added!",
                                //   buttons: [
                                //     DialogButton(
                                //       color: kPrimaryColor,
                                //       onPressed: () {
                                //         Navigator.pop(context);
                                //         Navigator.pop(context);
                                //       },
                                //       width: 120,
                                //       child: const Text(
                                //         "CLOSE",
                                //         style: TextStyle(
                                //             color: Colors.white, fontSize: 20),
                                //       ),
                                //     )
                                //   ],
                                // ).show();
                              } else {
                                // Alert(
                                //   context: context,
                                //   type: AlertType.error,
                                //   title: "ERROR",
                                //   desc:
                                //       "Unable to add expense, please try again",
                                //   buttons: [
                                //     DialogButton(
                                //       color: kPrimaryColor,
                                //       onPressed: () {
                                //         Navigator.pop(context);
                                //         setState(() {
                                //           isLoading = false;
                                //         });
                                //       },
                                //       width: 120,
                                //       child: const Text(
                                //         "CLOSE",
                                //         style: TextStyle(
                                //             color: Colors.white, fontSize: 20),
                                //       ),
                                //     )
                                //   ],
                                // ).show();
                              }
                            });
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
                                    Text("Save Expense"),
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
        });
  }

  editExpense(var expense) {
    TextEditingController expenseController = TextEditingController();
    TextEditingController paymentDateController = TextEditingController();
    TextEditingController expenseDescription = TextEditingController();

    paymentDateController.text = expense.date;
    expenseDescription.text = expense.description ?? "";
    expenseController.text = expense.amount;
    String expenseCategory = expense.category['id'].toString();

    bool isLoading = false;
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: StatefulBuilder(builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(20.0),
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(
                          "Edit Expenses of ${expense.amount}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
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
                    const Divider(),
                    Form(
                        child: Column(children: [
                      DropdownFormField<Map<String, dynamic>>(
                        emptyActionText: "",
                        onEmptyActionPressed: () async {},
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onChanged: (dynamic str) {
                          expenseCategory = str['id'].toString();
                        },
                        displayItemFn: (dynamic item) {
                          return Text(
                            (item ?? expense.category)['name'] ?? '',
                            style: const TextStyle(fontSize: 16),
                          );
                        },
                        findFn: (dynamic str) async => expenseCategories,
                        selectedFn: (dynamic item1, dynamic item2) {
                          if (item1 != null && item2 != null) {
                            return item1['name'] == item2['name'];
                          }
                          return false;
                        },
                        filterFn: (dynamic item, str) =>
                            item['name']
                                .toLowerCase()
                                .indexOf(str.toLowerCase()) >=
                            0,
                        dropdownItemFn: (dynamic item,
                                int position,
                                bool focused,
                                bool selected,
                                Function() onTap) =>
                            ListTile(
                          title: Text(item['name']),
                          tileColor: focused
                              ? const Color.fromARGB(20, 0, 0, 0)
                              : Colors.transparent,
                          onTap: onTap,
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      TextFormField(
                        controller: expenseController,
                        inputFormatters: [
                          ThousandsFormatter(allowFraction: true)
                        ],
                        onChanged: (value) {
                          setState(() {});
                        },
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Expense Amount",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      DateTimePicker(
                        controller: paymentDateController,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Date',
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      Container(
                        margin:
                            const EdgeInsets.only(top: 0, left: 5, right: 5),
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: kPrimaryColor),
                        child:  Container(
                          margin: const EdgeInsets.only(top: 0, left: 5, right: 5),
                          decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              color: Colors.white),
                          child: DropdownFormField<Map<String, dynamic>>(
                            controller: DatabaseHelper.instance.paymentController,
                            emptyActionText: "",
                            onEmptyActionPressed: () async {},
                            decoration: const InputDecoration(
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10)),
                                ),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                                labelText: "Select Payment Method"),
                            onChanged: (dynamic str) {
                            },
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
                            item['name']
                                .toLowerCase()
                                .indexOf(str.toLowerCase()) >=
                                0,
                            dropdownItemFn: (dynamic item,
                                int position,
                                bool focused,
                                bool selected,
                                Function() onTap) =>
                                ListTile(
                                  title: Text(item['name']),
                                  tileColor: focused
                                      ? const Color.fromARGB(20, 0, 0, 0)
                                      : Colors.transparent,
                                  onTap: onTap,
                                ),
                          ),

                          // DropDownTextField(
                          //   clearOption: true,
                          //   textFieldFocusNode: textFieldFocusNode,
                          //   searchFocusNode: searchFocusNode,
                          //   controller: DatabaseHelper.instance.paymentMethodsController,
                          //   searchAutofocus: true,
                          //   dropDownItemCount: 4,
                          //   searchShowCursor: true,
                          //   enableSearch: true,
                          //   searchKeyboardType: TextInputType.text,
                          //   textFieldDecoration: const InputDecoration(
                          //       hintText: "Payment Option",
                          //       hintStyle: TextStyle(fontSize: 16),
                          //       fillColor: Colors.white,
                          //       border: OutlineInputBorder(
                          //         borderRadius: BorderRadius.only(
                          //             topLeft: Radius.circular(10),
                          //             bottomLeft: Radius.circular(10)),
                          //         borderSide: BorderSide.none,
                          //       )),
                          //   searchDecoration: const InputDecoration(
                          //       fillColor: kPrimaryLightColor,
                          //       border: OutlineInputBorder(
                          //         borderRadius: BorderRadius.all(Radius.circular(0)),
                          //         borderSide: BorderSide.none,
                          //       )),
                          //   dropDownList: paymentMethods,
                          //   onChanged: (val) {
                          //     setState(() {
                          //       print(val.toString());
                          //       DatabaseHelper.instance.paymentMethodsController.dropDownValue =
                          //           val;
                          //     });
                          //   },
                          // ),
                        )
                        ,
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      TextFormField(
                        controller: expenseDescription,
                        maxLines: 4,
                        minLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 2.0,
                      ),
                    ])),
                    Row(
                      children: [
                        Expanded(
                            child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });
                            var data = {
                              'id': expense.id.toString(),
                              'amount':
                                  expenseController.text.replaceAll(',', ''),
                              'mode': DatabaseHelper
                                  .instance
                                  .paymentController?.value?['payId'],
                              'date': paymentDateController.text,
                              'category': expenseCategory,
                              'description': expenseDescription.text,
                              'transaction_status': 2
                            };
                            Requests.editExpenses(token, data).then((value) {
                              if (value == 'success') {
                                setState(() {
                                  fetchExpenses();
                                });
                                // Alert(
                                //   context: context,
                                //   type: AlertType.success,
                                //   title: "SUCCESS",
                                //   desc: "Expense was successfully added!",
                                //   buttons: [
                                //     DialogButton(
                                //       color: kPrimaryColor,
                                //       onPressed: () {
                                //         Navigator.pop(context);
                                //         Navigator.pop(context);
                                //       },
                                //       width: 120,
                                //       child: const Text(
                                //         "CLOSE",
                                //         style: TextStyle(
                                //             color: Colors.white, fontSize: 20),
                                //       ),
                                //     )
                                //   ],
                                // ).show();
                              } else {
                                // Alert(
                                //   context: context,
                                //   type: AlertType.error,
                                //   title: "ERROR",
                                //   desc:
                                //       "Unable to add expense, please try again",
                                //   buttons: [
                                //     DialogButton(
                                //       color: kPrimaryColor,
                                //       onPressed: () {
                                //         Navigator.pop(context);
                                //         setState(() {
                                //           isLoading = false;
                                //         });
                                //       },
                                //       width: 120,
                                //       child: const Text(
                                //         "CLOSE",
                                //         style: TextStyle(
                                //             color: Colors.white, fontSize: 20),
                                //       ),
                                //     )
                                //   ],
                                // ).show();
                              }
                            });
                          },
                          child: isLoading
                              ? const CupertinoActivityIndicator(
                                  radius:
                                      20, // Sets the radius of the progress indicator
                                  animating: true,
                                  color: Colors.white)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.save,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 5.0),
                                    Text("Save Changes"),
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
        });
  }

  deleteExpense(var expense) {
    bool isLoading = false;
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
                        Expanded(
                            child: Text(
                          "Delete Expenses of ${expense.amount}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
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
                    const Divider(),
                    const Text(
                      "Are you sure you want to delete this expense?\nProceed to delete expense.",
                      style: TextStyle(
                          fontWeight: FontWeight.w200, fontSize: 20.0),
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });
                            var data = {
                              'id': expense.id.toString(),
                            };
                            Requests.deleteExpenses(token, data).then((value) {
                              if (value == 'success') {
                                setState(() {
                                  fetchExpenses();
                                });
                                // Alert(
                                //   context: context,
                                //   type: AlertType.success,
                                //   title: "SUCCESS",
                                //   desc: "Expense was successfully deleted!",
                                //   buttons: [
                                //     DialogButton(
                                //       color: kPrimaryColor,
                                //       onPressed: () {
                                //         Navigator.pop(context);
                                //         Navigator.pop(context);
                                //       },
                                //       width: 120,
                                //       child: const Text(
                                //         "CLOSE",
                                //         style: TextStyle(
                                //             color: Colors.white, fontSize: 20),
                                //       ),
                                //     )
                                //   ],
                                // ).show();
                              } else {
                                // Alert(
                                //   context: context,
                                //   type: AlertType.error,
                                //   title: "ERROR",
                                //   desc:
                                //       "Unable to add expense, please try again",
                                //   buttons: [
                                //     DialogButton(
                                //       color: kPrimaryColor,
                                //       onPressed: () {
                                //         Navigator.pop(context);
                                //         setState(() {
                                //           isLoading = false;
                                //         });
                                //       },
                                //       width: 120,
                                //       child: const Text(
                                //         "CLOSE",
                                //         style: TextStyle(
                                //             color: Colors.white, fontSize: 20),
                                //       ),
                                //     )
                                //   ],
                                // ).show();
                              }
                            });
                          },
                          child: isLoading
                              ? const CupertinoActivityIndicator(
                                  radius:
                                      20, // Sets the radius of the progress indicator
                                  animating: true,
                                  color: Colors.white)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 5.0),
                                    Text("Proceed"),
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
        });
  }

  fetchPaymentMethods() {
    DatabaseHelper.instance.fetchPaymentMethods().then((value) {
      setState(() {
        paymentMethods = value;
      });
    });
  }

  Future fetchBusinessDetails() async {
    await DatabaseHelper.instance.fetchBusinessDetails().then((value) {
      token = value![0]['token'].toString();
      return value;
    });
  }

  Widget createTable() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Container(
                      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: DropdownSearch<String>(
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          showSelectedItems: true,
                          disabledItemFn: (String s) => s.startsWith('I'),
                        ),
                        items: expenseCategories
                            .map((category) => category['name'].toString())
                            .toList(),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            hintText: "Expense Categories",
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchedExpenses = expenses.where((expense) {
                              final expenseCategory =
                                  expense.category!['name'].toLowerCase();
                              final input = value!.toLowerCase();
                              return expenseCategory.contains(input);
                            }).toList();
                          });
                        },
                      ))),
              Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[900]),
                    onPressed: () {
                      expenseCategory();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [Icon(Icons.add), Text("Add Category")],
                    ),
                  )),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[900]),
                    onPressed: () {
                      addExpense();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [Icon(Icons.add), Text("Record Expense")],
                    ),
                  ))
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
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
                  child: Text('Expense Category',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white),
                  )),
              Expanded(
                  flex: 2,
                  child: Text(
                    'Made by',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white),
                  )),
              Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white),
                  )),
              Expanded(
                  flex: 2,
                  child: Text(
                    'Action',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.white),
                  )),
            ],
          ),
        ),
        Expanded(
            child: expenses.isNotEmpty ? ListView.builder(
                itemCount: searchedExpenses.length,
                itemBuilder: (context, index) {
                  var expense = searchedExpenses[index];
                  var sn = 1 + index;
                  return
                  InkWell(
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
                              flex: 2,
                              child: Text(
                                '${expense.category!['name']}',
                              )),
                          Expanded(
                              flex: 2,
                              child: Text(
                                '${expense.description}',
                              )),
                          Expanded(
                              flex: 2,
                              child: Text(
                                '${expense.user}',
                              )),
                          Expanded(
                              flex: 2,
                              child: Text(
                                '${expense.date}',
                              )),
                          Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      editExpense(expense);
                                    },
                                    child: const Tooltip(
                                      preferBelow: false,
                                      message: "Edit Expense",
                                      child: Icon(
                                        Icons.mode_edit_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10.0,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      deleteExpense(expense);
                                    },
                                    child: const Tooltip(
                                      preferBelow: false,
                                      message: "Delete Expense",
                                      child: Icon(
                                        Icons.delete_outline_outlined,
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                  );
                }) : const Center(child: CircularProgressIndicator()))
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
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Row(
                          children: const [
                            Tooltip(
                              message: "Sales window",
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 30.0,
                              ),
                            ),
                            Tooltip(
                              message: "Sales window",
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
                    ],
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    "Expenses",
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

class Expense {
  String? id;
  String? date;
  String? amount;
  Map<String, dynamic>? category;
  String? description;
  String? user;

  Expense(
      {this.id,
      this.date,
      this.amount,
      this.category,
      this.user,
      this.description});
}
