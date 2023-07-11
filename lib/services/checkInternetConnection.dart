import 'package:internet_connection_checker/internet_connection_checker.dart';

class CheckInternetConnection{

  Future<bool> checkInternetConnectivity() async {
    return await InternetConnectionChecker().hasConnection;
  }

}