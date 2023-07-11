import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../constants.dart';


class DiscountPopup extends StatefulWidget {
  // var runningSession;
  DiscountPopup({super.key});

  @override
  State<DiscountPopup> createState() => DiscountPopupState();
}

class DiscountPopupState extends State<DiscountPopup> {
  bool is_amount = true;
  TextEditingController inputs = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return AlertDialog(
      title: const Text("Add a discount"),
      content: Container(
        constraints: BoxConstraints(
          minHeight: screenHeight * 0.4,
          minWidth: screenWidth * 0.4,
          maxWidth: screenWidth * 0.4,
          maxHeight: screenHeight * 0.4,
        ),
        child: Column(
          children: [
            Expanded(
                child: Center(
                  child: ToggleSwitch(
                    minWidth: 120.0,
                    initialLabelIndex: is_amount ? 0 : 1,
                    cornerRadius: 20.0,
                    activeFgColor: Colors.white,
                    inactiveBgColor: Colors.grey,
                    inactiveFgColor: Colors.white,
                    totalSwitches: 2,
                    labels: const ['Amount', 'Percentage'],
                    icons: const [FontAwesomeIcons.moneyBill, FontAwesomeIcons.percent],
                    activeBgColors: [[Colors.blue],[Theme.of(context).primaryColor]],
                    onToggle: (index) {
                      if(index==0){
                        setState(() {
                          is_amount=true;
                          inputs.text="";
                        });
                      }else{
                        setState(() {
                          is_amount=false;
                          inputs.text="";
                        });
                      }
                    },
                  ),
                )
            ),
            Expanded(
              child: Container(
                child: TextField(
                  style: GoogleFonts.inter(
                    fontSize: 18.0,
                    color: const Color(0xFF151624),
                  ),
                  controller: inputs,
                  maxLines: 1,
                  // maxLength: is_amount? 12 : 5,
                  inputFormatters: [
                    // FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    // ThousandsFormatter()
                    ThousandsFormatter(allowFraction: true)
                  ],
                  keyboardType: TextInputType.number,
                  cursorColor: const Color(0xFF151624),
                  decoration: InputDecoration(
                    labelText: is_amount ? 'Enter Amount' : 'Enter Discount in %',
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
            Expanded(child:
            Card(
              color: kPrimaryColor,
              elevation: 4, // Controls the elevation of the card to give it a raised appearance
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Sets the border radius of the card to make it look rounded
              ),
              child: InkWell(
                onTap: () {
                  // Add your button press logic here
                  Navigator.of(context).pop();
                },
                child: Padding(
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
                elevation: 4, // Controls the elevation of the card to give it a raised appearance
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Sets the border radius of the card to make it look rounded
                ),
                child: InkWell(
                  onTap: () {
                    // Add your button press logic here
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Save',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),)
          ],
        )
      ],
    );
  }


}
