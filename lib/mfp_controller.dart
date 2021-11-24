import 'package:myfatoorah_flutter/utils/MFResult.dart';

class MFPController {
  final Function(String, String)? _initSession;
  final Function(String, Function(MFResult<String?> result) result)?
      _sumbitPayment;

  MFPController(this._initSession, this._sumbitPayment);

  // void initSessionListener(
  //     Function(String sessionId, String country) callback) {
  //   _initSession = callback;
  // }

  void initSession(String sessionId, String country) {
    _initSession?.call(sessionId, country);
  }

  void submitPayment(
      String language, Function(MFResult<String?>) result) {
    _sumbitPayment?.call(language, result);
  }
}
