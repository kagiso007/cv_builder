import 'package:flutter/material.dart';
import 'dart:async';

class Loadings {
//function starts here

  static Future<void> showLoading(BuildContext context, GlobalKey key) async {
//returning dialog which is void basically

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
//used to avoid closing of dialog by user click and back events
        return WillPopScope(
          onWillPop: () async => false,
          child: SimpleDialog(
            key: key,
            backgroundColor: Colors.white,
            children: const <Widget>[
              Center(
                child: Column(children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Loading..",
                  )
                ]),
              )
            ],
          ),
        );
      },
    );
  }
}
