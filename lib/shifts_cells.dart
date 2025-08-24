import 'package:flutter/material.dart';

const double cellWidth = 100;
const double cellHeight = 20;

class DateCell extends StatelessWidget {
  final String value;
  final Color color;


  const DateCell({super.key,
    this.value ='-',
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: cellWidth,
      height: cellHeight,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black12,
          width: 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),
      ),
    );
  }
}



class ShiftCell extends StatelessWidget {
  final String value;
  final Color color;

  const ShiftCell({super.key,
    this.value ='-',
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    const double cellWidth = 100;
    const double cellHeight = 20;
    return Container(
      width: cellWidth,
      height: cellHeight,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black12,
          width: 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: TextStyle(fontSize: 12.0),
      ),
    );
  }
}
