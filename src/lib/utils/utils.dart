import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kira_auth/utils/colors.dart';

void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 2,
    backgroundColor: KiraColors.purple1.withOpacity(0.8),
    webBgColor: KiraColors.white.withOpacity(0.8),
    textColor: KiraColors.purple1,
    webPosition: "center",
    fontSize: 16,
  );
}

void copyText(String message) {
  Clipboard.setData(ClipboardData(text: message));
}
