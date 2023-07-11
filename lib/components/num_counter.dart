import 'package:flutter/material.dart';

class NumericStepButton extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  NumericStepButton(
      {this.value = 1, required this.onChanged});

  @override
  State<NumericStepButton> createState() {
    return _NumericStepButtonState();
  }
}

class _NumericStepButtonState extends State<NumericStepButton> {

  // double counter = widget.value;
  double counter = 0;
  TextEditingController num_ctrl = TextEditingController();

  @override
  void initState() {
    counter=widget.value;
    num_ctrl.text=counter.toString();
  }

  void _handleEmptyTextField() {
    if (num_ctrl.text.isEmpty) {
      num_ctrl.text = '1';
      num_ctrl.selection = TextSelection(baseOffset: 0, extentOffset: num_ctrl.value.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.remove,
              color: Theme.of(context).accentColor,
            ),
            padding: EdgeInsets.symmetric(vertical:0, horizontal:0),
            iconSize: 15.0,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            color: Theme.of(context).primaryColor,
            onPressed: () {
              setState(() {
                if (counter > 0) {
                  counter--;
                }
                widget.onChanged(counter);
              });
            },
          ),
          // Text(
          //   '$counter',
          //   textAlign: TextAlign.center,
          //   style: TextStyle(
          //     color: Colors.black87,
          //     fontSize: 18.0,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: num_ctrl,
              decoration: const InputDecoration(
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                    borderSide: BorderSide.none,
                  )
              ),
              onTap: () {
                num_ctrl.selection = TextSelection(baseOffset: 0, extentOffset: num_ctrl.text.length);
              },
              onChanged: (value) {
                setState(() {
                  counter=double.parse(num_ctrl.text);
                  widget.onChanged(counter);
                });

              },
              onEditingComplete: (){
                _handleEmptyTextField();
              },




            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).accentColor,
            ),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical:0, horizontal:0),
            iconSize: 20.0,
            color: Theme.of(context).primaryColor,
            onPressed: () {
              setState(() {
                if (counter < 999999) {
                  counter++;
                }
                num_ctrl.text=counter.toString();
                widget.onChanged(counter);
              });
            },
          ),
        ],
      ),
    );
  }
}