import 'package:flutter/material.dart';
import 'package:myfatoorah_flutter/model/initsession/SDKInitSessionResponse.dart';
import 'package:myfatoorah_flutter/utils/AppConstants.dart';

import '../mfp_controller.dart';
import '../myfatoorah_flutter.dart';
import 'html_apple_pay_page.dart';

class MFAplePayCardView extends StatefulWidget {
  final Color inputColor;
  final Color labelColor;
  final Color errorColor;
  final Color borderColor;
  final int fontSize;
  final int borderWidth;
  final int borderRadius;
  final String cardHolderNameHint;
  final String cardNumberHint;
  final String expiryDateHint;
  final String cvvHint;
  final bool showLabels;
  final String cardHolderNameLabel;
  final String cardNumberLabel;
  final String expiryDateLabel;
  final String cvvLabel;
  int newCardHeight = 400;
  double fieldHeight = 32;
  String environment = "demo.myfatoorah.com";
  HtmlApplePayPage? htmlPage;
  late MFPController controller;
  final Function(MFPController) onFormReady;

  final String sessionId;
  final String countryCode;

  MFAplePayCardView({
    Key? key,
    this.inputColor = Colors.black,
    this.labelColor = Colors.black,
    this.errorColor = Colors.red,
    this.borderColor = Colors.grey,
    cardHeight = 400,
    this.fontSize = 14,
    this.borderWidth = 1,
    this.borderRadius = 8,
    this.cardHolderNameHint = "Name On Card",
    this.cardNumberHint = "Number",
    this.expiryDateHint = "MM / YY",
    this.cvvHint = "CVV",
    this.cardHolderNameLabel = "Card Holder Name",
    this.cardNumberLabel = "Card Number",
    this.expiryDateLabel = "ExpiryDate",
    this.cvvLabel = "Security Code",
    this.showLabels = true,
    required this.onFormReady,
    required this.sessionId,
    required this.countryCode,
  }) : super(key: key) {
    calculateHeights(cardHeight);
    setEnvironment();
    controller = initController();
    var html = generateHTML(sessionId, countryCode, newCardHeight);

    this.htmlPage = HtmlApplePayPage(html, () {
      onFormReady(controller);
    });
  }

  MFPController initController() {
    // Function(String, String)? _initSession = (sessionId, country) {
    //   MFSDK.initiateSession(sessionId, country,
    //       (MFInitiateSessionResponse result) {
    //     load(result);
    //   });
    // };

    Function(String, Function(MFResult<String?> result) result)?
        _submitPayment = (language, result) {
      syncServerSession(MFAPILanguage.EN, result);
    };

    return MFPController( _submitPayment);
  }

  void calculateHeights(cardHeight) {
    newCardHeight = cardHeight;

    var labelHeight = 32;

    var totalLabelsHeight = 0;

    if (showLabels)
      totalLabelsHeight = 4 * labelHeight;
    else
      totalLabelsHeight = (1.6 * labelHeight).toInt();

    if (!showLabels) newCardHeight -= totalLabelsHeight;

    fieldHeight = (newCardHeight - totalLabelsHeight) / 6;
  }

  void setEnvironment() {
    if (AppConstants.baseUrl == MFBaseURL.TEST)
      environment = "demo.myfatoorah.com";
    else
      environment = "portal.myfatoorah.com";
  }

  @override
  State<StatefulWidget> createState() {
    return htmlPage!;
  }

  String generateHTML(String sessionId, String countryCode, int newCardHeight) {
    return """
      <!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Embedded Payment</title>
    <style></style>
</head>

<body>
    <script src="https://demo.myfatoorah.com/applepay/v1/applepay.js"></script> 
   <div style="width:400px">
   <div id="card-element"></div>
   </div>
    

   <script>
    window.onload = () => {
        var config = {
              countryCode: "KWT",
              sessionId: "$sessionId",
            currencyCode: "${countryCode}", // Here, add your Currency Code.
            amount: "10", // Add the invoice amount.
            cardViewId: "card-element",
            callback: payment
        };

        myFatoorah.init(config);

        function payment(response) {
        
            // Here you need to pass session id to you backend here 
            var sessionId = response.SessionId;
            var cardBrand = response.CardBrand;
            callExecutePayment(sessionId);

        };
    }
   </script>
    
</body>

</html>
   
        """;
  }

  String convertToHex(Color inputColor) {
    var hex = inputColor.value.toRadixString(16);
    return hex.replaceRange(0, 2, "");
  }

  void load(MFInitiateSessionResponse initSessionResponse) {
    htmlPage!.load(
        generateHTML(initSessionResponse.sessionId!,
            initSessionResponse.countryCode!, this.newCardHeight),
        this.newCardHeight);
  }

  //Get data from server
  void syncServerSession(
      String apiLang, Function(MFResult<String?> result) callback) {
    htmlPage!.serverSubmit(apiLang, callback);
  }

// void pay(MFExecutePaymentRequest request, String apiLang, Function callback) {
//   htmlPage!.submit(request, apiLang, callback);
// }
}
