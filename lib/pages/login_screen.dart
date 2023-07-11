import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/colors/gf_color.dart';
import 'package:getwidget/components/progress_bar/gf_progress_bar.dart';
import 'package:poscream/components/databaseHelper.dart';
import 'package:poscream/pages/sales_window.dart';
import 'package:sqflite_common/sqlite_api.dart';
import '../components/already_have_an_account_acheck.dart';
import '../components/components.dart';
import '../constants.dart';
import '../services/api.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formKey = GlobalKey<FormState>();
  var progressPercentage = 0.0;

  //Controllers
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  FocusNode userNameFocusNode = FocusNode();
  bool showLoginLoader = false;
  bool showPassword = false;

  Widget loginPageAssets =
      Column(mainAxisAlignment: MainAxisAlignment.end, children: [
    Image.asset(
      "assets/images/poscream.png",
      height: 150,
    ),
    const SizedBox(height: defaultPadding * 6),
    Image.asset("assets/images/graphic_new.png"),
    const SizedBox(height: defaultPadding * 4),
  ]);
  login() {
    if (formKey.currentState!.validate()) {
      setState(() {
        showLoginLoader = true;
      });

      var logins = {
        "username": username.text,
        "password": password.text,
      };

      Requests.login(logins).then((value) async {
        Database? database = await DatabaseHelper.instance.database;
        if (value.runtimeType.toString() == "_Map<String, dynamic>") {
          var myData = {
            "token": value['token'],
            "fullName": value['user']['names'],
            "email": value['user']['uemail'],
            "userPhone1": value['user']['phone1'],
            "username": value['user']['uname'],
            "userId": value['user']['id'],
            "userStatus": value['user']['status'],
            "businessId": value['user']['business']['id'],
            "businessName": value['user']['business_name'],
            "businessAddress": value['user']['business']['address'],
            "businessLogo": value['user']['business']['Businesslogo'] ?? "",
            "businessPhone1": value['user']['business']['phone1'],
            "businessPhone2": value['user']['business']['phone2'] ?? "",
            "businessTin": value['user']['business']['tin'] ?? "",
            "businessStatus": value['businessStatus'],
            "branchId": value['user']['branch']['id'],
            "branchName": value['user']['branch_name'],
            "branchAddress": value['user']['branch']['address'],
            "branchPhone1": value['user']['branch']['phone1'],
            "branchPhone2": value['user']['branch']['phone2'] ?? "",
            "branchStatus": value['branchStatus'],
            "loginStatus": "0",
            "editSellingPrice": value['user']['role']['edit_selling_price'],
            "viewGeneralSettings": value['user']['role']['view_general_settings'],
            "viewReceiptSettings": value['user']['role']['view_receipt_settings'],
          };
          var token = value['token'];
          const totalEndPoints = 6;
          setState(() {
            progressPercentage = (1 / totalEndPoints);
          });
          database?.delete(DatabaseHelper.userTable).then((value) {
            database
                ?.insert(DatabaseHelper.userTable, myData)
                .then((value) async {
              successLogin();
              await fetchServerSettings(token).then((value) {
                setState(() {
                  progressPercentage = (2 / totalEndPoints);
                });
              });
             await fetchServerPaymentMethods(token).then((value){
               setState(() {
                 progressPercentage = (3 / totalEndPoints);
               });
              });
              await fetchServerCustomers(token).then((value) {
                setState(() {
                  progressPercentage = (4 / totalEndPoints);
                });
              });
             await fetchServerProducts(token).then((value) {
               setState(() {
                 progressPercentage = (5 / totalEndPoints);
               });
              });

              await fetchServerReceiptSettings(token).then((value) {
                setState(() {
                  progressPercentage = (6 / totalEndPoints);
                });
              });

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const SalesScreen();
                    },
                  ),
                );
              }
            });
          });
        } else if (value == "invalid") {
          setState(() {
            showLoginLoader = false;
            //userNameFocusNode.requestFocus();
          });
          invalidLogins();
        } else {
          setState(() {
            showLoginLoader = false;
          });
          timeOut();
        }
      });
    }
  }

  void successLogin() {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 6),
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'SUCCESS',
        message:
        'You were logged in successfully.\nJust a moment as we fetch your data!!',
        contentType: ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);

  }

  void invalidLogins() {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 6),
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Login Error',
        message:
        'The logins provided are invalid, please try again',
        contentType: ContentType.warning,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  void timeOut() {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 6),
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Network Failure',
        message:
        'We were unable to handle this request.\nCheckout your internet connection and try again latern',
        contentType: ContentType.failure,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Widget loginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if(progressPercentage > 0 ) Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.downloading,
              color: Colors.white,
              size: 50.0,
            ),
            const Text(
              "Loading data....",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.0),
            ),
            const SizedBox(
              height: 20.0,
            ),
            GFProgressBar(
                percentage: progressPercentage,
                backgroundColor : Colors.black26,
                progressBarColor: GFColors.SUCCESS,
              lineHeight: 14,
              child:  Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text("${(progressPercentage * 100).toStringAsFixed(0)}%", textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
          ],
        ),
        Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "LOGIN HERE",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 18),
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                focusNode: userNameFocusNode,
                controller: username,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                // focusNode: userNameFocusNode,
                validator: (value) {
                  if (value!.isEmpty) {
                    return ('Please enter your username');
                  }
                },
                textInputAction: TextInputAction.next,
                cursorColor: kPrimaryColor,
                onSaved: (email) {},
                decoration: const InputDecoration(
                  hintText: "Username",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Icon(
                      Icons.person,
                      color: kPrimaryColor,
                    ),
                  ),
                  errorStyle: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                child: TextFormField(
                  obscureText: !showPassword,
                  controller: password,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return ('Please enter your password');
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  cursorColor: kPrimaryColor,
                  decoration: InputDecoration(
                    errorStyle: const TextStyle(
                      color: Colors.white,
                    ),
                    hintText: "Password",
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(defaultPadding),
                      child: Icon(
                        Icons.lock,
                        color: kPrimaryColor,
                      ),
                    ),
                    suffixIcon: InkWell(
                      onTap: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Icon(showPassword
                            ? Icons.visibility
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),
              Hero(
                tag: "login_btn",
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromRGBO(86, 71, 40, 1)),
                  ),
                  onPressed: () {
                    //first validate the form before submitting
                    login();
                  },
                  child: showLoginLoader
                      ? const CupertinoActivityIndicator(
                          radius:
                              20, // Sets the radius of the progress indicator
                          animating: true,
                          color: kPrimaryLightColor
                          // Controls whether the progress indicator is animating or not
                          )
                      : const Text(
                          "LOGIN",
                        ),
                ),
              ),
              const SizedBox(height: defaultPadding),
              AlreadyHaveAnAccountCheck(
                press: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) {
                  //       return SignUpScreen();
                  //     },
                  //   ),
                  // );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    //userNameFocusNode.requestFocus();

    //Check if user is already logged in and just proceed
    DatabaseHelper.instance.fetchBusinessDetails().then((value) {
      if (value!.isNotEmpty) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return const SalesScreen();
        }));
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.enter): () {
            login();
          },
        },
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: loginPageAssets,
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                height: MediaQuery.of(context).size.height,
                color: loginColor,
                child: loginForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
