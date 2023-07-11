import 'dart:convert';

import 'package:dio/dio.dart';
// const root = "https://newapp.poscreamug.com/api";
const root = "https://demoback.poscreamug.com/api";

class Links {
  static const login = "$root/login";
  static const fetchProducts = "$root/fetchpdts";
  static const fetchCustomers = "$root/customers";
  static const fetchPaymentMethods = "$root/payment_options";
  static const submitSales = "$root/appsales";
  static const addCustomer = "$root/customers";
  static const expenses = "$root/expenses";
  static const expenseCategories = "$root/expense_categories";
  static const debtors = "$root/expense_categories";
  static const settings = "$root/general_settings";
  static const batchSales = "$root/app_batchsales";
  static const receiptSettings = "$root/receipt_settings";
}

class Requests{
  //login request
   static Future<dynamic> login(var logins) async {
    var headers = {
      "Accept": "application/json",
      "content-Type": "application/json",
    };

    var options = BaseOptions(
      connectTimeout: 10000,
      receiveTimeout: 10000,
      headers: headers,
    );

    try {
      var dio = Dio(options);
      //server login url
      var url = Links.login;
      final response = await dio.post(url, data: logins);
      if (response.statusCode == 200) {
        var message = response.data;
        return message;
      } else if(response.statusCode == 202){
        //Represents invalid login details
        return "invalid";
      }else {
        print("status code");
        print("${response.statusCode}");
        print("status code");
        return "error";
      }
    } catch (e) {
      print(e.toString());
      return "error";
    }
  }

  //fetch products request
   static Future<dynamic> products(String token) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 30000,
       receiveTimeout: 60000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.fetchProducts;

       final response = await dio.get(url);
       if (response.statusCode == 200) {
         var message = response.data;

         return message['data'];
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //fetch customers
   static Future<dynamic> customers(String token) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.fetchCustomers;

       final response = await dio.get(url);

       if (response.statusCode == 200) {
         var message = response.data;
         return message['data'];
       }else if(response.statusCode != 200){
         customers(token);
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //fetch payment methods
   static Future<dynamic> paymentMethods(String token) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.fetchPaymentMethods;
       final response = await dio.get(url);
       if (response.statusCode == 200) {
         var message = response.data;
         return message['data'];
       } else if(response.statusCode != 200){
         paymentMethods(token);
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //Synchronize sales
   static Future<dynamic> submitSales(String token, var data) async {

     try {

       var headers = {
         "Accept": "application/json",
         "content-Type": "application/json",
         'Authorization': 'Bearer $token'
       };

       var options = BaseOptions(
         connectTimeout:20000,
         receiveTimeout: 20000,
         headers: headers,
       );

       var dio = Dio(options);

       // SERVER LOGIN API URL
       var url = Links.submitSales;
       final response = await dio.post(url, data: data);
       var msg = response.data;
       var res = msg['sale_id'];
       return res.toString();

     } on DioError catch (e) {
       print(e.message);
       print(e.response);
     }
   }

   //Add customer
   static Future<dynamic> addCustomer(String token, var data) async {

     try {

       var headers = {
         "Accept": "application/json",
         "content-Type": "application/json",
         'Authorization': 'Bearer $token'
       };

       var options = BaseOptions(
         connectTimeout:20000,
         receiveTimeout: 20000,
         headers: headers,
       );

       var dio = Dio(options);

       // SERVER LOGIN API URL
       var url = Links.addCustomer;
       final response = await dio.post(url, data: data);
       if(response.statusCode==200){
         return "success";
       }else{
         return "error";
       }

     } on DioError catch (e) {
       print(e.message);
       print(e.response);
       return "error";
     }
   }

   //fetch expenses
   static Future<dynamic> fetchExpenses(String token) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.expenses;

       final response = await dio.get(url);
       if (response.statusCode == 200) {
         var message = response.data;

         return message['data'];
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //fetch expenses
   static Future<dynamic> addExpenses(String token, data) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.expenses;

       final response = await dio.post(url, data: data);
       if (response.statusCode == 200) {
         return "success";
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //Edit Expenses
   static Future<dynamic> editExpenses(String token, data) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = "${Links.expenses}/${data['id']}";

       final response = await dio.put(url, data: data);
       if (response.statusCode == 200) {
         return "success";
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //Delete Expenses
   static Future<dynamic> deleteExpenses(String token, data) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = "${Links.expenses}/${data['id']}";

       final response = await dio.delete(url);
       if (response.statusCode == 200) {
         return "success";
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //Fetch expense categories
   static Future<dynamic> fetchExpenseCategories(String token) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.expenseCategories;

       final response = await dio.get(url);
       if (response.statusCode == 200) {
         var data = response.data['data'];
         return data;
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //Fetch Debtors
   static Future<dynamic> fetchDebtors(String token) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.expenseCategories;

       final response = await dio.get(url);
       if (response.statusCode == 200) {
         var data = response.data['data'];
         return data;
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //Add expense category
   static Future<dynamic> addExpenseCategory(String token, var data) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.expenseCategories;

       final response = await dio.post(url, data: data);
       if (response.statusCode == 200) {
         return "success";
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //Fetch settings
   static Future<dynamic> fetchSettings(String token) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.settings;
       final response = await dio.get(url);
       if (response.statusCode == 200) {
         var data = response.data;
         return data;
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //sending batch sales
   static Future<dynamic> submitBatchSales(String token, var data) async {

     try {

       var headers = {
         "Accept": "application/json",
         "content-Type": "application/json",
         'Authorization': 'Bearer $token'
       };

       var options = BaseOptions(
         connectTimeout:30000,
         receiveTimeout: 30000,
         headers: headers,
       );

       var dio = Dio(options);

       // SERVER LOGIN API URL
       var url = Links.batchSales;
       final response = await dio.post(url, data: {'items': data});
       if(response.statusCode == 200){
         var results = response.data;
         return results['sale_ids'];
       }else{
         print(response.statusCode);
         print(response.data);
       }

     } on DioError catch (e) {
       print(e.message);
       print(e.response);
     }
   }

   //Fetches receipt settings
   static Future<dynamic> fetchReceiptSettings(String token) async {

     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = Links.receiptSettings;
       final response = await dio.get(url);
       if (response.statusCode == 200) {
         var data = response.data;
         return data;
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //change receipt settings
   static Future<dynamic> changeReceiptSettings(String token, var data) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = "${Links.receiptSettings}/${data['id']}";
       final response = await dio.put(url, data: data);
       if (response.statusCode == 200) {
         return "success";
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

   //change general settings
   static Future<dynamic> changeGeneralSettings(String token, var data) async {
     // headers
     var headers = {
       "Accept": "application/json",
       "content-Type": "application/json",
       "Authorization": "Bearer $token"
     };

     var options = BaseOptions(
       connectTimeout: 20000,
       receiveTimeout: 20000,
       headers: headers,
     );

     try {
       var dio = Dio(options);
       //server fetch products url
       var url = "${Links.settings}/${data['id']}";
       final response = await dio.put(url, data: data);
       if (response.statusCode == 200) {
         return "success";
       } else {
         return "error";
       }
     } catch (e) {
       print(e.toString());
       return "error";
     }
   }

}