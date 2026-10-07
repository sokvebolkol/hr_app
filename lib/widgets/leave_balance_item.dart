import 'package:flutter/material.dart';

class DividerItem extends StatelessWidget {
  const DividerItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.grey[300], thickness: 1, height: 20);
  }
}
