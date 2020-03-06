import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/invoice_model.dart';
import 'package:flutter/foundation.dart';
import 'package:invoiceninja_flutter/data/web_client.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/ui/app/loading_indicator.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';
import 'package:native_pdf_view/native_pdf_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';

Future<Null> viewPdf(InvoiceEntity invoice, BuildContext context) async {
  final localization = AppLocalization.of(context);
  if (Platform.isIOS) {
    if (await canLaunch(invoice.invitationBorderlessLink)) {
      await launch(invoice.invitationBorderlessLink,
          forceSafariVC: true, forceWebView: true);
    } else {
      throw localization.anErrorOccurred;
    }

    return;
  }

  showDialog<Scaffold>(
      context: context,
      builder: (BuildContext context) {
        final localization = AppLocalization.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(localization.invoice + ' ' + (invoice.number ?? '')),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  localization.download,
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  launch(invoice.invitationDownloadLink,
                      forceSafariVC: false, forceWebView: false);
                },
              ),
            ],
          ),
          body: Container(
            color: Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FutureBuilder(
                future: renderPDF(context, invoice),
                builder: (BuildContext context,
                    AsyncSnapshot<List<PDFPageImage>> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.active:
                    case ConnectionState.waiting:
                      return LoadingIndicator();
                    case ConnectionState.done:
                      if (snapshot.hasError)
                        return Text(
                            '${getPdfRequirements(context)} - Error: ${snapshot.error}');
                      else
                        return snapshot.data.length == 1
                            ? Center(
                                child: Container(
                                  color: Colors.white,
                                  child: Image(
                                      image: MemoryImage(
                                          snapshot.data.first.bytes),
                                      height: double.infinity),
                                ),
                              )
                            : ListView(
                                scrollDirection: Axis.horizontal,
                                children: snapshot.data
                                    .map((page) => Row(
                                          children: <Widget>[
                                            Container(
                                              width: 20,
                                              height: double.infinity,
                                              color: Colors.grey,
                                            ),
                                            Container(
                                              color: Colors.white,
                                              child: ExtendedImage.memory(
                                                page.bytes,
                                                fit: BoxFit.fitHeight,
                                              ),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              );
                  }
                  return null; // unreachable
                }),
          ),
        );
      });
}

Future<List<PDFPageImage>> renderPDF(
    BuildContext context, InvoiceEntity invoice) async {
  /*
  url =
      //'https://staging.invoiceninja.com/download/gj5d2udwzowatfsjibarq4eyo4k0cvpd'; // one page
      'https://staging.invoiceninja.com/download/9gsjumkd8yaujcr0trnucnwfrelt1hil'; // four pages
  */

  final state = StoreProvider.of<AppState>(context).state;

  // TODO fix this
  final invitation = invoice.invitations.first;
  final url = invitation.downloadLink;
  print('## URL: $url');
  final request = await HttpClient().getUrl(Uri.parse(url));

  request.headers.add('X-API-Token', state.userCompany.token.token);
  final response = await request.close();
  final bytes = await consolidateHttpClientResponseBytes(response);

  final document = await PDFDocument.openData(bytes);
  final List<PDFPageImage> pages = [];
  for (var i = 1; i <= document.pagesCount; i++) {
    final page = await document.getPage(1);
    final pageImage = await page.render(width: page.width, height: page.height);
    pages.add(pageImage);
    page.close();
  }

  return pages;
}
