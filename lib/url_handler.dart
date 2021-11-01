part of 'myfatoorah_flutter.dart';

class _AppBarSpecs {
  String title = "MyFatoorah Payment";
  Color titleColor = Color(0xffffffff);
  Color backgroundColor = Color(0xff0495ca);
  bool isShowAppBar = true;
}

class PaymentUrlHandler extends StatefulWidget {
  final String invoiceId;
  final String paymentURL;
  final bool isDirectPayment;
  final _SDKListener sdkListener;
  final _AppBarSpecs appBarSpecs;
  final NavigatorState? navigator;

  PaymentUrlHandler({
    this.navigator,
    required this.invoiceId,
    required this.paymentURL,
    this.isDirectPayment = false,
    required this.sdkListener,
    required this.appBarSpecs,
  });

  @override
  _PaymentUrlHandlerState createState() => new _PaymentUrlHandlerState();
}

class _PaymentUrlHandlerState extends State<PaymentUrlHandler> {
  double progress = 0.0;
  WebViewController? _webViewController;
  bool _webViewVisibility = true;
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  late StreamSubscription<double> _onProgressChanged;
  late StreamSubscription<WebViewStateChanged> _onStateChanged;

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    BackButtonInterceptor.add(myCancelButtonInterceptor);

    if (Platform.isIOS) {
      _onStateChanged = flutterWebViewPlugin.onStateChanged
          .listen((WebViewStateChanged state) {
        String url = state.url;

        if (mounted) {
          if ((url.contains(AppConstants.callBackUrl!) ||
              url.contains(AppConstants.errorUrl!))) {
            checkCallBacks(url, widget.navigator?.context ?? context);
          }
        }
      });

      _onProgressChanged =
          flutterWebViewPlugin.onProgressChanged.listen((double progress) {
        if (mounted) {
          _setProgressBar(progress.toString());
        }
      });
    }
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myCancelButtonInterceptor);
    if (Platform.isIOS) {
      _onProgressChanged.cancel();
      _onStateChanged.cancel();
    }
    super.dispose();
  }

  bool myCancelButtonInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    widget.sdkListener.onCancelButtonClicked(widget.invoiceId);
    return true;
  }

  void _setProgressBar(String value) {
    setState(() {
      this.progress = double.tryParse(value)!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widget.appBarSpecs.isShowAppBar ||
              Theme.of(context).platform == TargetPlatform.iOS)
          ? AppBar(
              title: Text(widget.appBarSpecs.title,
                  style: TextStyle(color: widget.appBarSpecs.titleColor)),
              backgroundColor: widget.appBarSpecs.backgroundColor,
              actionsIconTheme: IconThemeData(
                color: widget.appBarSpecs.titleColor,
              ),
              actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.autorenew),
                    onPressed: () {
                      _setProgressBar("0");
                      reloadWebView();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () {
                      widget.sdkListener
                          .onCancelButtonClicked(widget.invoiceId);
                    },
                  ),
                ])
          : null,
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(0, 1, 0, 1),
            child: isStillProgress(progress)
                ? LinearProgressIndicator(value: setProgress(progress))
                : Container(),
          ),
          if (_webViewVisibility)
            Expanded(
              child: getWebView(widget.paymentURL),
            ),
        ],
      ),
    );
  }

  Widget getWebView(String paymentURL) {
    if (Platform.isAndroid)
      return getWebViewForAndroid(paymentURL);
    else
      return getWebViewForIOS(paymentURL);
  }

  Widget getWebViewForAndroid(String paymentURL) {
    return WebView(
      initialUrl: paymentURL,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) {
        _webViewController = webViewController;
      },
      onProgress: (int progress) {
        _setProgressBar(progress.toString());
      },
      navigationDelegate: (NavigationRequest request) {
        print("navigationDelegate url: " + request.url);
        checkCallBacks(request.url, context);
        return NavigationDecision.navigate;
      },
      onPageFinished: (String url) {
        print('Page finished loading: $url');
      },
      gestureNavigationEnabled: true,
    );
  }

  Widget getWebViewForIOS(String paymentURL) {
    return WebviewScaffold(
      url: paymentURL,
      withJavascript: true,
      mediaPlaybackRequiresUserGesture: false,
      withZoom: true,
      withLocalStorage: true,
      hidden: false,
      clearCache: true,
      initialChild: Container(
        color: Colors.white,
        child: const Center(
          child: Text('Waiting...'),
        ),
      ),
    );
  }

  Future<void> checkCallBacks(String url, BuildContext context) async {
    Uri uri = Uri.dataFromString(url);
    final lastPart = uri.pathSegments.lastOrNull;
    String? paymentId = uri.queryParameters["paymentId"];
    log('[checkCallBacks] paymentId: $paymentId, lastPart: $lastPart');
    if (paymentId != null &&
        lastPart != null &&
        lastPart.toLowerCase() == "result") {
      setWebViewVisibility(false);
      final request = MFPaymentStatusRequest(paymentId: paymentId);
      final res = await widget.sdkListener.fetchPaymentStatusByAPI(
        invoiceId: widget.invoiceId,
        request: request,
        isDirectPayment: widget.isDirectPayment,
      );
      log('[checkCallBacks] FOUND RESULT !! calling fetchPaymentStatusByAPI now');
      widget.navigator?.pop(res);
    }
  }

  void setWebViewVisibility(bool status) {
    setState(() {
      _webViewVisibility = status;
    });
  }

  isStillProgress(double progress) {
    if (Platform.isIOS)
      return progress < 1.0;
    else
      return progress < 100.0;
  }

  double setProgress(double progress) {
    if (Platform.isIOS)
      return progress;
    else
      return progress / 100.0;
  }

  Future<void> reloadWebView() async {
    if (Platform.isIOS) {
      await flutterWebViewPlugin.reload();
    } else {
      await _webViewController?.reload();
    }
  }
}
