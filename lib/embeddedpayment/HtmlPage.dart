import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:myfatoorah_flutter/model/MFError.dart';
import 'package:myfatoorah_flutter/utils/ErrorsEnum.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../myfatoorah_flutter.dart';
import 'MFPaymentCardView.dart';

class HtmlPage extends State<MFPaymentCardView> {
  static int cardHeight = 220;
  static String html = "";
  static late MFExecutePaymentRequest request;
  static late String apiLang;
  static late Function(MFResult<String?>) callback;
  static WebViewController? _webViewController;

  HtmlPage(String htmlCode) {
    html = htmlCode;
  }

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  void load(String htmlCode, int cardH) {
    html = htmlCode;
    cardHeight = cardH;
    _webViewController!.loadUrl(
        new Uri.dataFromString(html, mimeType: 'text/html').toString());
  }

  void serverSubmit(String lang, Function(MFResult<String?> result) func) {
    MFExecutePaymentRequest defaultRequest =
        MFExecutePaymentRequest.constructorDefault();
    request = defaultRequest;
    apiLang = lang;
    callback = func;
    _webViewController!.evaluateJavascript('submit()');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cardHeight.toDouble(),
      child: GestureDetector(
        onHorizontalDragUpdate: (updateDetails) {},
        onVerticalDragUpdate: (updateDetails) {},
        child: WebView(
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _webViewController = webViewController;
            },
            javascriptChannels: Set.from([
              JavascriptChannel(
                  name: 'Success',
                  onMessageReceived: (JavascriptMessage message) {
                    executePayment(context, message.message);
                  }),
              JavascriptChannel(
                  name: 'Fail',
                  onMessageReceived: (JavascriptMessage message) {
                    returnPaymentFailed(message.message);
                  })
            ]),
            initialUrl:
                new Uri.dataFromString(html, mimeType: 'text/html').toString()),
      ),
    );
  }

  void executePayment(BuildContext context, String sessionId) {
    request.sessionId = sessionId;

    request.invoiceValue = 1;
    MFResult<String?> result = MFResult.success<String>(sessionId);
    callback.call(result);
  }

  void returnPaymentFailed(String error) {
    // callback(MFResult.fail<MFPaymentStatusResponse>(new MFError(
    //     ErrorHelper.getValue(ErrorsEnum.EMBEDDED_PAYMENT_ERROR).code, error)));
  }
}