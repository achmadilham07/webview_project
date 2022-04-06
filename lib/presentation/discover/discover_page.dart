/*
 * Copyright (c) 2021 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/repository.dart';
import '../../helpers/string_formatters.dart';
import '../app_colors.dart';
import 'widgets/footer_widget.dart';
import 'widgets/navigation_controls_widget.dart';

/// Discover new websites tab
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    Key? key,
    required this.repository,
    required this.routeToSavedUrlsTab,
  }) : super(key: key);

  final Repository repository;
  final void Function() routeToSavedUrlsTab;

  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // TODO 02: add WebViewController here
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  String? url;
  String? prevUrl;
  bool isLoading = true;
  String? invalidUrl;

  Repository get repository => widget.repository;
  bool get shouldSendUrlToHelpPage => invalidUrl != null;
  String get domainName => StringFormatters.getDomainNameFromUrl(url);

  @override
  void initState() {
    onImFeelingLuckyPressed();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: buildAppBar(),
      body: url == null
          ? const CircularProgressIndicator()
          : Column(
              children: [
                Expanded(
                  child: buildWebView(context),
                ),
                FooterWidget(
                  /// add this after TODO 03
                  navigationControls: NavigationControls(
                    webViewController: _controller.future,
                    isLoading: isLoading,
                  ),
                  url: url,
                  routeToHelpPage: routeToHelpPage,
                ),
              ],
            ),
    );
  }

  Widget buildWebView(BuildContext context) {
    // TODO 01: Add WebView
    return WebView(
      /// You specified an [initialUrl] for what page to display first.
      initialUrl: url,

      /// [javascriptMode] allows you to control what kind of JavaScript can run in your web view. By default, JavaScript execution is disabled. You set it to [JavascriptMode.unrestricted] to enable it.
      javascriptMode: JavascriptMode.unrestricted,

      /// [onProgress] and [onPageFinished] are callback functions that you trigger when the page is loading and finished loading, respectively. You passed [onProgressWebView] to set the [isLoading] state, and [onPageFinishedWebView] to check if the URL is valid and toggle [isLoading].
      onProgress: onProgressWebView,
      onPageFinished: onPageFinishedWebView,

      /// By setting [gestureNavigationEnabled] to true, you can use horizontal swipe gestures to trigger back-forward list navigations on the [WebView] for iOS.
      gestureNavigationEnabled: true,

      /// add this after TODO 02
      onWebViewCreated: _controller.complete,
      onWebResourceError: _controller.completeError,

      /// add this after TODO 08
      navigationDelegate: getNavigationDelegate,

      /// add this after TODO 15. You can trigger JavaScript functions to refetch random URLs and route to another tab.
      /// This action can be process when you press the button "Check" on help page. 
      javascriptChannels: <JavascriptChannel>{
        refreshUrlJavascriptChannel(context),
        routeToSavedWebsitesJavascriptChannel(context),
      },
    );
  }

  void onPageFinishedWebView(String? _) {
    if (shouldSendUrlToHelpPage) {
      // TODO 10: Send url to web page. You can now see the invalid URL when you automatically navigate to the help page.
      sendUrlToHelpPageJavascriptFunction(invalidUrl!, url!);

      setState(() {
        invalidUrl = null;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  void onProgressWebView(int? _) {
    setState(() {
      isLoading = true;
    });
  }

  AppBar buildAppBar() {
    return AppBar(
      title: const Text('URL Gems'),
      actions: [
        ElevatedButton(
          onPressed: () async => onImFeelingLuckyPressed(),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) {
                return AppColors.accentColor;
              },
            ),
          ),
          child: const Text(
            "I'm feeling lucky!",
            style: TextStyle(color: Colors.white),
          ),
        ),
        IconButton(
          onPressed: onSaveUrlPressed,
          icon: const Icon(Icons.save),
        ),
      ],
    );
  }

  void onSaveUrlPressed() async {
    setState(() {
      isLoading = true;
    });
    if (url != null) {
      await repository.saveUrl(url!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $url!'),
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> routeToHelpPage() async {
    final contentBase64 = await repository.fetchHelpHtmlPage();
    setState(() {
      prevUrl = url;
      url = contentBase64;
    });
    await loadUrlOnWebView('data:text/html;base64,$contentBase64');
  }

  void onImFeelingLuckyPressed() async {
    final fetchedUrl = await widget.repository.getRandomUrl(exclude: url);
    setState(() {
      url = fetchedUrl;
    });
    await loadUrlOnWebView(fetchedUrl);
  }

  Future<void> loadUrlOnWebView(String url) async {
    // TODO 03: load url to be displayed on WebView
    final controller = await _controller.future;
    controller.loadUrl(url);
  }

  // TODO 08: Add Navigation Delegate to prevent navigation to certain domains
  Future<NavigationDecision> getNavigationDelegate(
      NavigationRequest request) async {
    if (request.url.contains(domainName)) {
      /// In case the URL was valid, you return [NavigationDecision.navigate]. You give the green light to the [WebView] to proceed with the navigation.
      return NavigationDecision.navigate;
    }

    if (!request.isForMainFrame) {
      /// Some pages you view change the URL in order to open modals or ads. When this happens, the [request.isForMainFrame] boolean is [false]. To prevent navigation in that case, you return [NavigationDecision.prevent].
      return NavigationDecision.prevent;
    }

    /// You set [invalidUrl] with the URL you get from the [NavigationRequest].
    setState(() {
      invalidUrl = request.url;
    });

    /// Since you detected navigation to an invalid URL, you force navigating to the help page.
    await routeToHelpPage();

    /// You prevent navigation to the requested invalid URL.
    return NavigationDecision.prevent;
  }

  // TODO 09: Send data to web page function
  void sendUrlToHelpPageJavascriptFunction(
      String invalidUrlToBeDisplayed, String urlToBeDisplayed) async {
    _controller.future.then((controller) {
      /// Called [runJavascript], which evaluates the passed string as JavaScript inside the HTML page that you load.
      controller.runJavascript(
        /// Passed a raw string that calls a JavaScript function named displayInvalidUrl. You passed both the invalid URL and the domain name that you should navigate within.
        '''displayInvalidUrl('$invalidUrlToBeDisplayed', '$urlToBeDisplayed')''',
      ).then((result) {});
    });
  }

  // TODO 14: receive RefreshUrl message from web page
  JavascriptChannel refreshUrlJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'RefreshUrl',
        onMessageReceived: (_) {
          onImFeelingLuckyPressed();
        });
  }

  // TODO 15: receive RouteToSavedWebsites message from web page
  JavascriptChannel routeToSavedWebsitesJavascriptChannel(
      BuildContext context) {
    return JavascriptChannel(
        name: 'RouteToSavedWebsites',
        onMessageReceived: (_) {
          widget.routeToSavedUrlsTab();
        });
  }
}
