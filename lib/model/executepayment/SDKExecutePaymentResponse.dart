import 'package:myfatoorah_flutter/model/MyBaseResponse.dart';

class SDKExecutePaymentResponse extends MyBaseResponse {
  MFExecutePaymentResponse? data;

  SDKExecutePaymentResponse({this.data});

  SDKExecutePaymentResponse.fromJson(Map<String, dynamic> json) {
    data = json['Data'] != null
        ? new MFExecutePaymentResponse.fromJson(json['Data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['Data'] = this.data!.toJson();
    }
    return data;
  }
}

class MFExecutePaymentResponse {
  int? invoiceId;
  bool? isDirectPayment;
  String? paymentURL;
  String? customerReference;
  String? userDefinedField;

  MFExecutePaymentResponse(
      {this.invoiceId,
      this.isDirectPayment,
      this.paymentURL,
      this.customerReference,
      this.userDefinedField});

  MFExecutePaymentResponse.fromJson(Map<String, dynamic> json) {
    invoiceId = json['InvoiceId'];
    isDirectPayment = json['IsDirectPayment'];
    paymentURL = json['PaymentURL'];
    customerReference = json['CustomerReference'];
    userDefinedField = json['UserDefinedField'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['InvoiceId'] = this.invoiceId;
    data['IsDirectPayment'] = this.isDirectPayment;
    data['PaymentURL'] = this.paymentURL;
    data['CustomerReference'] = this.customerReference;
    data['UserDefinedField'] = this.userDefinedField;
    return data;
  }
}
