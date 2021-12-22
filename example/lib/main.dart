import 'package:flutter/material.dart';
import 'package:myfatoorah_flutter/mfp_controller.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';

/*
TODO: The following API token key for testing only, so that when you go live
      don't forget to replace the following key with the live key provided
      by MyFatoorah.
*/

// You can get the API Token Key from here:
// https://myfatoorah.readme.io/docs/test-token
final String mAPIKey =
    "YcI4hYz8avvM8UerN833ACQui60VfSRnBvSB7sdcx_A49b6uO1YzoLEhGVYqCZtXezSDF3brM2U7jUo59nSNjFvcMWBTKhDIpVoPP0_q8A6EFtMDafyMpb9wy59L6MbUb_lxCpuJKJb6CIu6pLb_Yea409CHB46-HFmhBsqkvz4sVjsmvaP3DZjWgToGX3KO6Gi3VD6IV8NaW8wZcKgVVsb_5wE46CRsBCHD2K02i_qXi0pv_S6q7oqH-eKTMz6bqYijKPvMj82hkrx16E1pc0YEnkII6BjexvsJZu1oeK3Bgsd91ZVofFF8yAsSQDwPcsfooYQccK17l4AFqKp3NiIgy8vg2aHK--NxTDxjla8OGIyhR-9gjSgG_KdbMce6uBB-qw1F1MSzf3GVyFQCqO9piDofv9ivrEzzSsziPDyGuo0ptuNmIPEhLEWUYYSZ3J4Cj80igACMOk4uFTnrtAB4ab4OhE6MFyoq-PtjsGC-zG3eO8C9C4IdyU20OVEl3AilRr2E4V9DaPK0lA8iwSAPyWC9w2sNnRLcbB2bFJgP4yESFPcGqfCKEvvhxOcl9zW3gvII-0ZdrzUlVSCcLBdpEHeFHp3NtBXuE1IBPpzq5p8Xz_Qiax77BzFam8Ol7L2-7eF60kfayAo1W_RcfqxGivXdlQ_s9U4gkCg-X2C3iE09cstjGsi1SdYFY57vxwSpZQ";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFatoorah Plugin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'MyFatoorah Plugin Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _response = '';
  String _loading = "Loading...";
  var sessionIdValue = "";
  late MFPController controller;

  @override
  void initState() {
    super.initState();

    if (mAPIKey.isEmpty) {
      setState(() {
        _response =
            "Missing API Token Key.. You can get it from here: https://myfatoorah.readme.io/docs/test-token";
      });
      return;
    }
    MFSDK.init(MFBaseURL.TEST, mAPIKey);
  }

  void initiateSession() {}

//   void payWithEmbeddedPayment() {
//     mfPaymentCardView.syncServerSession(
//         MFAPILanguage.EN,
//             (MFResult<String?> result) {
//
// print("SSSS");
//           // if (result.isSuccess()) {
//           //   print("Success: " + result.response!);
//           //   // setState(() {
//           //   //   print("Response: " +
//           //   //       result.response);
//           //   //   _response = result.response!.toJson().toString().toString();
//           //   // })
//           // } else {
//           //   setState(() {
//           //     print("Response: " +
//           //         result.error!.toJson().toString().toString());
//           //     _response = result.error!.message!;
//           //   });
//           // }
//         }
//     );
//
//     // var request = MFExecutePaymentRequest.constructor(0.100);
//     // mfPaymentCardView.pay(
//     //     request,
//     //     MFAPILanguage.EN,
//     //     (String invoiceId, MFResult<MFPaymentStatusResponse> result) => {
//     //           if (result.isSuccess())
//     //             {
//     //               setState(() {
//     //                 print("invoiceId: " + invoiceId);
//     //                 print("Response: " + result.response!.toJson().toString());
//     //                 _response = result.response!.toJson().toString();
//     //               })
//     //             }
//     //           else
//     //             {
//     //               setState(() {
//     //                 print("invoiceId: " + invoiceId);
//     //                 print("Error: " + result.error!.toJson().toString());
//     //                 _response = result.error!.message!;
//     //               })
//     //             }
//     //         });
//   }

  /*
    Send Payment
   */
  // void sendPayment() {
  //   MFSDK.initiateSession("0753cab9-5d4c-ec11-baf2-0022488426d2",(MFInitiateSessionResponse result) {
  //     mfPaymentCardView.load(result);
  //   });
  // }

  /*
    Initiate Payment
   */
  void initiatePayment() {
    var request = new MFInitiatePaymentRequest(5.5, MFCurrencyISO.KUWAIT_KWD);

    MFSDK.initiatePayment(
        request,
        MFAPILanguage.EN,
        (MFResult<MFInitiatePaymentResponse> result) => {
              if (result.isSuccess())
                {
                  setState(() {
                    print("Response: " + result.response!.toJson().toString());
                    _response = result.response!.toJson().toString().toString();
                  })
                }
              else
                {
                  setState(() {
                    print("Response: " + result.error!.toJson().toString());
                    _response = result.error!.message!;
                  })
                }
            });

    setState(() {
      _response = _loading;
    });
  }

  /*
    Execute Regular Payment
   */
  void executeRegularPayment() {
    // The value 1 is the paymentMethodId of KNET payment method.
    // You should call the "initiatePayment" API to can get this id and the ids of all other payment methods
    int paymentMethod = 1;

    var request = new MFExecutePaymentRequest(paymentMethod, 0.100);

    MFSDK.executePayment(
        context,
        request,
        MFAPILanguage.EN,
        (String invoiceId, MFResult<MFPaymentStatusResponse> result) => {
              if (result.isSuccess())
                {
                  setState(() {
                    print("invoiceId: " + invoiceId);
                    print("Response: " + result.response!.toJson().toString());
                    _response = result.response!.toJson().toString().toString();
                  })
                }
              else
                {
                  setState(() {
                    print("invoiceId: " + invoiceId);
                    print("Response: " + result.error!.toJson().toString());
                    _response = result.error!.message!;
                  })
                }
            });

    setState(() {
      _response = _loading;
    });
  }

  /*
    Execute Direct Payment
   */
  void executeDirectPayment() {
    // The value 9 is the paymentMethodId of Visa/Master payment method.
    // You should call the "initiatePayment" API to can get this id and the
    // ids of all other payment methods
    int paymentMethod = 9;

    var request = new MFExecutePaymentRequest(paymentMethod, 0.100);

//    var mfCardInfo = new MFCardInfo(cardToken: "Put your API token key here");

    var mfCardInfo = new MFCardInfo(
        cardNumber: "5453010000095489",
        expiryMonth: "05",
        expiryYear: "21",
        securityCode: "100",
        cardHolderName: "Set Name",
        bypass3DS: false,
        saveToken: false);

    MFSDK.executeDirectPayment(
        context,
        request,
        mfCardInfo,
        MFAPILanguage.EN,
        (String invoiceId, MFResult<MFDirectPaymentResponse> result) => {
              if (result.isSuccess())
                {
                  setState(() {
                    print("invoiceId: " + invoiceId);
                    print("Response: " + result.response!.toJson().toString());
                    _response = result.response!.toJson().toString().toString();
                  })
                }
              else
                {
                  setState(() {
                    print("invoiceId: " + invoiceId);
                    print("Response: " + result.error!.toJson().toString());
                    _response = result.error!.message!;
                  })
                }
            });

    setState(() {
      _response = _loading;
    });
  }

  /*
    Execute Direct Payment with Recurring
   */
  void executeDirectPaymentWithRecurring() {
    // The value 20 is the paymentMethodId of Visa/Master payment method.
    // You should call the "initiatePayment" API to can get this id and the ids
    // of all other payment methods
    int paymentMethod = 20;

    var request = new MFExecutePaymentRequest(paymentMethod, 100.0);

    var mfCardInfo = new MFCardInfo(
        cardNumber: "5453010000095539",
        expiryMonth: "05",
        expiryYear: "21",
        securityCode: "100",
        cardHolderName: "Set Name",
        bypass3DS: true,
        saveToken: true);

    mfCardInfo.iteration = 12;

    MFSDK.executeRecurringDirectPayment(
        context,
        request,
        mfCardInfo,
        MFRecurringType.monthly,
        MFAPILanguage.EN,
        (String invoiceId, MFResult<MFDirectPaymentResponse> result) => {
              if (result.isSuccess())
                {
                  setState(() {
                    print("Response: " + invoiceId);
                    print("Response: " + result.response!.toJson().toString());
                    _response = result.response!.toJson().toString().toString();
                  })
                }
              else
                {
                  setState(() {
                    print("Response: " + invoiceId);
                    print("Response: " + result.error!.toJson().toString());
                    _response = result.error!.message!;
                  })
                }
            });

    setState(() {
      _response = _loading;
    });
  }

  /*
    Payment Enquiry
   */
  void getPaymentStatus() {
    var request = MFPaymentStatusRequest(invoiceId: "457786");

    MFSDK.getPaymentStatus(
        MFAPILanguage.EN,
        request,
        (MFResult<MFPaymentStatusResponse> result) => {
              if (result.isSuccess())
                {
                  setState(() {
                    print("Response: " + result.response!.toJson().toString());
                    _response = result.response!.toJson().toString().toString();
                  })
                }
              else
                {
                  setState(() {
                    print("Response: " + result.error!.toJson().toString());
                    _response = result.error!.message!;
                  })
                }
            });

    setState(() {
      _response = _loading;
    });
  }

  /*
    Cancel Token
   */
  void cancelToken() {
    MFSDK.cancelToken(
        "Put your token here",
        MFAPILanguage.EN,
        (MFResult<bool> result) => {
              if (result.isSuccess())
                {
                  setState(() {
                    print("Response: " + result.response.toString());
                    _response = result.response.toString();
                  })
                }
              else
                {
                  setState(() {
                    print("Response: " + result.error!.toJson().toString());
                    _response = result.error!.message!;
                  })
                }
            });

    setState(() {
      _response = _loading;
    });
  }

  /*
    Cancel Recurring Payment
   */
  void cancelRecurringPayment() {
    MFSDK.cancelRecurringPayment(
        "Put RecurringId here",
        MFAPILanguage.EN,
        (MFResult<bool> result) => {
              if (result.isSuccess())
                {
                  setState(() {
                    print("Response: " + result.response.toString());
                    _response = result.response.toString();
                  })
                }
              else
                {
                  setState(() {
                    print("Response: " + result.error!.toJson().toString());
                    _response = result.error!.message!;
                  })
                }
            });

    setState(() {
      _response = _loading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // body: MFAplePayCardView(
      //   onFormReady: (MFPController controller) {
      //     this.controller = controller;
      //     // controller.initSession("024d5706-4d63-ec11-baf2-0022488426d2", "KWT");
      //   },
      //   sessionId: '024d5706-4d63-ec11-baf2-0022488426d2',
      //   countryCode: 'KWT',
      // ),
      body: MFPaymentCardView(
        sessionId: '024d5706-4d63-ec11-baf2-0022488426d2',
        countryCode: 'KWT',
        onFormReady: (MFPController controller) {
          this.controller = controller;
          // controller.initSession("de24994a-315f-ec11-baf2-0022488426d2", "KWT");
        },
      ),
    );
  }

//   createPaymentCardView() {
//     mfPaymentCardView = MFPaymentCardView(
// //      inputColor: Colors.red,
// //      labelColor: Colors.yellow,
// //      errorColor: Colors.blue,
// //      borderColor: Colors.green,
// //      fontSize: 14,
// //      borderWidth: 1,
// //      borderRadius: 10,
// //      cardHeight: 220,
// //      cardHolderNameHint: "card holder name hint",
// //      cardNumberHint: "card number hint",
// //      expiryDateHint: "expiry date hint",
// //      cvvHint: "cvv hint",
// //      showLabels: true,
// //      cardHolderNameLabel: "card holder name label",
// //      cardNumberLabel: "card number label",
// //      expiryDateLabel: "expiry date label",
// //      cvvLabel: "cvv label",
//     );
//
//     return mfPaymentCardView;
//   }
}
