import 'package:flutter/cupertino.dart';
import 'back.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const CupertinoPageScaffold(
          backgroundColor: Color(0xFF1C1C1E),
          child: Center(
            child: Text(
              'Schermata Shop',
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
        ),
        const CustomBackButton(),
      ],
    );
  }
}
