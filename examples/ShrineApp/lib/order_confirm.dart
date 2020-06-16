import 'package:flutter/material.dart';

class OrderConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: Text("Thank you!"),
      backgroundColor: Colors.white,
      content: Container(
        child: Text("Your order has been confirmed."),
      ),
    );
  }
}