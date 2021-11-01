import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import 'package:myfatoorah_flutter/model/MFError.dart';
import 'package:myfatoorah_flutter/model/MyBaseResponse.dart';
import 'package:myfatoorah_flutter/model/cancelrecurring/SDKCancelRecurringResponse.dart';
import 'package:myfatoorah_flutter/model/canceltoken/SDKCancelTokenResponse.dart';
import 'package:myfatoorah_flutter/model/directpayment/MFCardInfo.dart';
import 'package:myfatoorah_flutter/model/directpayment/MFDirectPaymentResponse.dart';
import 'package:myfatoorah_flutter/model/directpayment/SDKDirectPaymentResponse.dart';
import 'package:myfatoorah_flutter/model/executepayment/MFExecutePaymentRequest.dart';
import 'package:myfatoorah_flutter/model/executepayment/SDKExecutePaymentResponse.dart';
import 'package:myfatoorah_flutter/model/initpayment/MFInitiatePaymentRequest.dart';
import 'package:myfatoorah_flutter/model/initpayment/SDKInitiatePaymentResponse.dart';
import 'package:myfatoorah_flutter/model/paymentstatus/MFPaymentStatusRequest.dart';
import 'package:myfatoorah_flutter/model/paymentstatus/SDKPaymentStatusResponse.dart';
import 'package:myfatoorah_flutter/model/sendpayment/MFSendPaymentRequest.dart';
import 'package:myfatoorah_flutter/model/sendpayment/SDKSendPaymentResponse.dart';
import 'package:myfatoorah_flutter/utils/APIUtils.dart';
import 'package:myfatoorah_flutter/utils/AppConstants.dart';
import 'package:myfatoorah_flutter/utils/ErrorsEnum.dart';
import 'package:myfatoorah_flutter/utils/MFRecurringType.dart';
import 'package:myfatoorah_flutter/utils/MFResult.dart';
import 'package:myfatoorah_flutter/utils/SourceInfo.dart';

import 'model/initsession/SDKInitSessionResponse.dart';
import 'utils/ErrorUtils.dart';

// Export all MyFatoorah SDK classes to can be visible to sdk end users
export 'package:myfatoorah_flutter/model/directpayment/MFCardInfo.dart';
export 'package:myfatoorah_flutter/model/directpayment/MFDirectPaymentResponse.dart';
export 'package:myfatoorah_flutter/model/executepayment/MFExecutePaymentRequest.dart';
export 'package:myfatoorah_flutter/model/initpayment/MFInitiatePaymentRequest.dart';
export 'package:myfatoorah_flutter/model/paymentstatus/MFPaymentStatusRequest.dart';
export 'package:myfatoorah_flutter/model/sendpayment/MFSendPaymentRequest.dart';
export 'package:myfatoorah_flutter/model/paymentstatus/SDKPaymentStatusResponse.dart';
export 'package:myfatoorah_flutter/model/sendpayment/SDKSendPaymentResponse.dart';
export 'package:myfatoorah_flutter/model/initpayment/SDKInitiatePaymentResponse.dart';
export 'package:myfatoorah_flutter/utils/MFResult.dart';
export 'package:myfatoorah_flutter/utils/MFAPILanguage.dart';
export 'package:myfatoorah_flutter/utils/MFInvoiceLanguage.dart';
export 'package:myfatoorah_flutter/utils/MFCurrencyISO.dart';
export 'package:myfatoorah_flutter/utils/MFMobileISO.dart';
export 'package:myfatoorah_flutter/utils/MFNotificationOption.dart';
export 'package:myfatoorah_flutter/utils/MFRecurringType.dart';
export 'package:myfatoorah_flutter/utils/MFBaseURL.dart';
export 'package:myfatoorah_flutter/embeddedpayment/MFPaymentCardView.dart';
part 'url_handler.dart';

// ignore: non_constant_identifier_names
var MFSDK = new MyFatoorahFlutter();

class MyFatoorahFlutter implements _SDKListener {
  static const MethodChannel _channel =
      const MethodChannel('myfatoorah_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Function? func;
  late BuildContext myContext;
  String apiLang = "en";

  _AppBarSpecs appBarSpecs = _AppBarSpecs();

  void setUpAppBar({title, titleColor, backgroundColor, isShowAppBar}) {
    appBarSpecs = _AppBarSpecs();

    if (title != null) appBarSpecs.title = title;
    if (titleColor != null) appBarSpecs.titleColor = titleColor;
    if (backgroundColor != null) appBarSpecs.backgroundColor = backgroundColor;
    if (isShowAppBar != null) appBarSpecs.isShowAppBar = isShowAppBar;
  }

  void init(String baseUrl, String token) {
    AppConstants.baseUrl = baseUrl;
    if (token.startsWith("bearer"))
      AppConstants.apiKey = token;
    else if (token.isNotEmpty) AppConstants.apiKey = "bearer " + token;
  }

  // Send Payment
  void sendPayment(BuildContext context, String apiLang,
      MFSendPaymentRequest request, Function func) async {
    this.apiLang = apiLang;

    request.sourceInfo = await SourceInfo(context).getData();

    http.Response response =
        await callAPI(AppConstants.sendPayment, apiLang, jsonEncode(request));

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      func(MFResult.fail<MFSendPaymentResponse>(mfError));
      return;
    }

    var result =
        SDKSendPaymentResponse.fromJson(json.decode(response.body)).data;

    func(MFResult.success(result));
  }

  // Initiate Payment
  void initiatePayment(
      MFInitiatePaymentRequest request, String apiLang, Function func) async {
    this.apiLang = apiLang;

    http.Response response = await callAPI(
        AppConstants.initiatePayment, apiLang, jsonEncode(request));

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      func(MFResult.fail<MFInitiatePaymentResponse>(mfError));
      return;
    }

    var result =
        SDKInitiatePaymentResponse.fromJson(json.decode(response.body)).data;

    if (Platform.isAndroid) {
      for (int i = 0; i < result!.paymentMethods!.length; i++) {
        if (result.paymentMethods![i].paymentMethodCode == "ap") {
          result.paymentMethods!.removeAt(i);
          break;
        }
      }
    }

    func(MFResult.success(result));
  }

  // Execute Payment
  void executePayment(BuildContext context, MFExecutePaymentRequest request,
      String apiLang, Function func) async {
    if (request.paymentMethodId == null) {
      func(
          "",
          MFResult.fail<MFPaymentStatusResponse>(ErrorHelper.getValue(
              ErrorsEnum.EXECUTE_PAYMENT_WITHOUT_PAYMENT_METHOD_ID_ERROR)));
      return;
    }

    callExecutePayment(context, request, apiLang, func);
  }

  void callExecutePayment(BuildContext context, MFExecutePaymentRequest request,
      String apiLang, Function func) async {
    this.apiLang = apiLang;

    if (request.callBackUrl == null || request.callBackUrl!.isEmpty)
      request.callBackUrl = AppConstants.callBackUrl;
    else
      AppConstants.callBackUrl = request.callBackUrl;

    if (request.errorUrl == null || request.errorUrl!.isEmpty)
      request.errorUrl = AppConstants.errorUrl;
    else
      AppConstants.errorUrl = request.errorUrl;

    request.sourceInfo = await SourceInfo(context).getData();

    http.Response response = await callAPI(
        AppConstants.executePayment, apiLang, jsonEncode(request));

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      func("", MFResult.fail<MFPaymentStatusResponse>(mfError));
      return;
    }

    var result =
        SDKExecutePaymentResponse.fromJson(json.decode(response.body)).data!;

    if (!result.isDirectPayment!) {
      this.func = func;
      this.myContext = context;
      showWebView(
        invoiceId: result.invoiceId.toString(),
        paymentURL: result.paymentURL!,
        isDirectPayment: false,
      );
    } else
      func(
          result.invoiceId.toString(),
          MFResult.fail<MFPaymentStatusResponse>(
              ErrorHelper.getValue(ErrorsEnum.INCORRECT_PAYMENT_METHOD_ERROR)));
  }

  // Execute Direct Payment
  void executeDirectPayment(
      BuildContext context,
      MFExecutePaymentRequest request,
      MFCardInfo mfCardInfo,
      String apiLang,
      Function func) async {
    this.apiLang = apiLang;

    var error = validateCardInfo(mfCardInfo.card!)!;
    if (error.isNotEmpty) {
      func(
          "",
          MFResult.fail<MFDirectPaymentResponse>(MFError(
              ErrorHelper.getValue(ErrorsEnum.INVALID_CARD_NUMBER_ERROR).code,
              error)));
      return;
    }

    if (request.callBackUrl == null || request.callBackUrl!.isEmpty)
      request.callBackUrl = AppConstants.callBackUrl;
    else
      AppConstants.callBackUrl = request.callBackUrl;

    if (request.errorUrl == null || request.errorUrl!.isEmpty)
      request.errorUrl = AppConstants.errorUrl;
    else
      AppConstants.errorUrl = request.errorUrl;

    request.sourceInfo = await SourceInfo(context).getData();

    http.Response response = await callAPI(
        AppConstants.executePayment, apiLang, jsonEncode(request));

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      func("", MFResult.fail<MFDirectPaymentResponse>(mfError));
      return;
    }

    var result =
        SDKExecutePaymentResponse.fromJson(json.decode(response.body)).data!;

    if (result.isDirectPayment!) {
      directPayment(context, apiLang, result.invoiceId, result.paymentURL,
          mfCardInfo, func);
    } else
      func(
          "",
          MFResult.fail<MFDirectPaymentResponse>(
              ErrorHelper.getValue(ErrorsEnum.DIRECT_PAYMENT_NOT_FOUND_ERROR)));
  }

  // Execute Direct Payment with Recurring
  @Deprecated("Use 'executeRecurringDirectPayment' instead.")
  void executeDirectPaymentWithRecurring(
      BuildContext context,
      MFExecutePaymentRequest request,
      MFCardInfo mfCardInfo,
      int intervalDays,
      String apiLang,
      Function func) async {
    mfCardInfo.setRecurringIntervalDays(intervalDays);
    executeDirectPayment(context, request, mfCardInfo, apiLang, func);
  }

  void executeRecurringDirectPayment(
      BuildContext context,
      MFExecutePaymentRequest request,
      MFCardInfo mfCardInfo,
      MFRecurringType mfRecurringType,
      String apiLang,
      Function func) async {
    mfCardInfo.setRecurringPeriod(mfRecurringType);
    executeDirectPayment(context, request, mfCardInfo, apiLang, func);
  }

  // Direct Payment
  void directPayment(BuildContext context, String apiLang, int? invoiceId,
      String? paymentURL, MFCardInfo request, Function func) async {
    this.apiLang = apiLang;

    http.Response response =
        await callAPI(paymentURL, apiLang, jsonEncode(request));

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      func(invoiceId.toString(),
          MFResult.fail<MFDirectPaymentResponse>(mfError));
      return;
    }

    var result = SDKDirectPaymentResponse.fromJson(json.decode(response.body));

    if (result.isSuccess!) {
      if (request.bypass3DS!) {
        var request = MFPaymentStatusRequest(paymentId: result.data!.paymentId);

        _paymentStatus(
          apiLang,
          request,
          func,
          isDirectPayment: true,
          cardInfoResponse: result.data,
          invoiceId: invoiceId.toString(),
        );
      } else {
        this.func = func;
        this.myContext = context;
        showWebView(
          invoiceId: invoiceId.toString(),
          paymentURL: result.data!.paymentURL!,
          isDirectPayment: true,
        );
      }
    } else {
      var error = MyBaseResponse.fromJson(json.decode(response.body));
      var errorMsg = parseErrorMessage(error);
      if (errorMsg == null || errorMsg.isEmpty)
        errorMsg = result.data!.errorMessage;

      func(
          invoiceId.toString(),
          MFResult.fail<MFDirectPaymentResponse>(new MFError(
              ErrorHelper.getValue(ErrorsEnum.PAYMENT_TRANSACTION_FAILED_ERROR)
                  .code,
              errorMsg)));
    }
  }

  // Payment Status
  Future<MFResult> _paymentStatus(
    String apiLang,
    MFPaymentStatusRequest request,
    Function? func, {
    bool isDirectPayment = false,
    DirectPaymentResponse? cardInfoResponse,
    String? invoiceId,
  }) async {
    this.apiLang = apiLang;

    http.Response response =
        await callAPI(AppConstants.paymentStatus, apiLang, jsonEncode(request));

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      final res = MFResult.fail<MFPaymentStatusResponse>(mfError);
      func?.call(invoiceId, MFResult.fail<MFPaymentStatusResponse>(mfError));

      return res;
    }

    var result = SDKPaymentStatusResponse.fromJson(json.decode(response.body));
    MFResult navResult;
    if (result.isSuccess != null && result.isSuccess!) {
      var transactionError =
          _checkIsPaymentTransactionSuccess(result.data!.invoiceTransactions!)!;

      if (transactionError.isNotEmpty) {
        var mfError = new MFError(
            ErrorHelper.getValue(ErrorsEnum.PAYMENT_TRANSACTION_FAILED_ERROR)
                .code,
            transactionError);
        if (isDirectPayment) {
          navResult = MFResult.fail<MFDirectPaymentResponse>(mfError);
          func?.call(invoiceId, navResult);
        } else {
          navResult = MFResult.fail<MFPaymentStatusResponse>(mfError);
          func?.call(invoiceId, navResult);
        }
      } else {
        if (isDirectPayment) {
          navResult = MFResult.success(
              MFDirectPaymentResponse(result.data, cardInfoResponse));
          func?.call(invoiceId, navResult);
        } else {
          navResult = MFResult.success(result.data);
          func?.call(invoiceId, navResult);
        }
      }
    } else {
      var error = MyBaseResponse.fromJson(json.decode(response.body));
      navResult = MFResult.fail<MFPaymentStatusResponse>(
        new MFError(statusCode, parseErrorMessage(error)),
      );
      func?.call(invoiceId, navResult);
    }

    log('[_paymentStatus] Parsed result: $navResult');
    return navResult;
  }

  String? _checkIsPaymentTransactionSuccess(
      List<InvoiceTransactions> invoiceTransactions) {
    var isSuccess = false;
    var index = 0;

    for (var i = 0; i < invoiceTransactions.length; i++) {
      if (invoiceTransactions[i].transactionStatus ==
          AppConstants.TRANSACTION_SUCCESS) {
        isSuccess = true;
        index = i;
        break;
      } else
        index = i;
    }

    if (isSuccess)
      return "";
    else
      return invoiceTransactions[index].error;
  }

  // Payment Status
  void getPaymentStatus(
      String apiLang, MFPaymentStatusRequest request, Function func) async {
    this.apiLang = apiLang;

    http.Response response =
        await callAPI(AppConstants.paymentStatus, apiLang, jsonEncode(request));

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      func(MFResult.fail<MFPaymentStatusResponse>(mfError));
      return;
    }

    var result = SDKPaymentStatusResponse.fromJson(json.decode(response.body));

    if (result.isSuccess != null && result.isSuccess!) {
      var transactionError =
          _checkIsPaymentTransactionSuccess(result.data!.invoiceTransactions!)!;

      if (transactionError.isNotEmpty) {
        func(MFResult.fail<MFPaymentStatusResponse>(new MFError(
            ErrorHelper.getValue(ErrorsEnum.PAYMENT_TRANSACTION_FAILED_ERROR)
                .code,
            transactionError)));
      } else
        func(MFResult.success(result.data));
    } else {
      var error = MyBaseResponse.fromJson(json.decode(response.body));
      func(MFResult.fail<MFPaymentStatusResponse>(new MFError(
          ErrorHelper.getValue(ErrorsEnum.BAD_REQUEST_ERROR).code,
          parseErrorMessage(error))));
    }
  }

  // Cancel Token
  void cancelToken(String token, String apiLang, Function func) async {
    this.apiLang = apiLang;

    var queryParameters = {
      'token': token,
    };

    var uri = Uri.https(AppConstants.baseUrl.replaceFirst("https://", ""),
        AppConstants.cancelToken, queryParameters);

    http.Response response = await callAPI(null, apiLang, null, uri: uri);

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      func(MFResult.fail<bool>(mfError));
      return;
    }

    var result = SDKCancelTokenResponse.fromJson(json.decode(response.body));

    if (result.isSuccess != null && result.isSuccess!) {
      func(MFResult.success(result.data));
    } else {
      var error = MyBaseResponse.fromJson(json.decode(response.body));
      func(MFResult.fail<bool>(
          new MFError(statusCode, parseErrorMessage(error))));
    }
  }

  // Cancel Recurring Payment
  void cancelRecurringPayment(
      String recurringId, String apiLang, Function func) async {
    this.apiLang = apiLang;

    var queryParameters = {
      'recurringId': recurringId,
    };

    var uri = Uri.https(AppConstants.baseUrl.replaceFirst("https://", ""),
        AppConstants.cancelRecurringPayment, queryParameters);

    http.Response response = await callAPI(null, apiLang, null, uri: uri);

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      func(MFResult.fail<bool>(mfError));
      return;
    }

    var result =
        SDKCancelRecurringResponse.fromJson(json.decode(response.body));

//      print(result.toJson());

    if (result.isSuccess != null && result.isSuccess!) {
      func(MFResult.success(result.data));
    } else {
      var error = MyBaseResponse.fromJson(json.decode(response.body));
      func(MFResult.fail<bool>(
          new MFError(statusCode, parseErrorMessage(error))));
    }
  }

  // Initiate Session
  void initiateSession(Function func) async {
    http.Response response =
        await callAPI(AppConstants.initSession, apiLang, "{}");

    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400) {
      var mfError = getErrorMsg(statusCode, response.body);
      func(MFResult.fail<String>(mfError));
      return;
    }

    var result =
        SDKInitiateSessionResponse.fromJson(json.decode(response.body)).data;

    func(MFResult.success(result));
  }

  Future<Object?> showWebView({
    required String invoiceId,
    required String paymentURL,
    bool isDirectPayment = false,
    NavigatorState? navigator,
  }) =>
      (navigator ?? Navigator.of(myContext)).push(
        MaterialPageRoute(
          builder: (context) => PaymentUrlHandler(
            invoiceId: invoiceId,
            paymentURL: paymentURL,
            isDirectPayment: isDirectPayment,
            sdkListener: this,
            appBarSpecs: appBarSpecs,
            navigator: navigator,
          ),
        ),
      );

  @override
  Future<MFResult> fetchPaymentStatusByAPI({
    required String invoiceId,
    required MFPaymentStatusRequest request,
    required bool isDirectPayment,
  }) async {
    return await _paymentStatus(
      apiLang,
      request,
      func,
      isDirectPayment: isDirectPayment,
      invoiceId: invoiceId,
    );
  }

  @override
  void onCancelButtonClicked(String invoiceId) {
    Navigator.pop(myContext);
    func!(
        invoiceId,
        MFResult.fail<MFPaymentStatusResponse>(
            ErrorHelper.getValue(ErrorsEnum.PAYMENT_CANCELLED_ERROR)));
  }
}

abstract class _SDKListener {
  Future<MFResult> fetchPaymentStatusByAPI({
    required String invoiceId,
    required MFPaymentStatusRequest request,
    required bool isDirectPayment,
  });

  void onCancelButtonClicked(String invoiceId);
}

class MyfatoorahSdk {
  static const MethodChannel _channel =
      const MethodChannel('myfatoorah_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
