import 'package:flutter/material.dart';
import 'package:poscream/constants.dart';
import 'package:settings_ui/settings_ui.dart';

class UsersSettings extends StatefulWidget {
  const UsersSettings({Key? key}) : super(key: key);

  @override
  State<UsersSettings> createState() => _UsersSettingsState();
}

class _UsersSettingsState extends State<UsersSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(child: SettingsList(
            sections: [
              SettingsSection(
                title: Text('Users Settings'),
                tiles: <SettingsTile>[

                  SettingsTile.navigation(
                    leading: Icon(Icons.people_rounded),
                    title: Text('Manage Users'),
                    // value: Text('Cash'),
                  ),
                  SettingsTile.navigation(
                    leading: Container(width: 25,),
                    description: Text(
                      "NOTE: You cannot modify your own user permissions",
                      style: TextStyle(color: darkColor, fontWeight: FontWeight.bold),
                    ),
                    title: Text('Manage User Permissions'),
                    // value: Text('Last 3 Weeks'),
                  ),


                ],
              ),
            ],
          ),),
        ],
      ),
    );
  }
}
