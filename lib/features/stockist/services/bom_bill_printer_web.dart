// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void printHtmlDocument(String htmlContent) {
  try {
    const iframeId = '__karatflow_thermal_printer_iframe__';
    final existingIframe = html.document.getElementById(iframeId);
    if (existingIframe != null) {
      existingIframe.remove();
    }

    final iframe = html.IFrameElement()
      ..id = iframeId
      ..style.position = 'fixed'
      ..style.left = '-9999px'
      ..style.top = '-9999px'
      ..style.width = '80mm'
      ..style.height = '600px'
      ..style.border = 'none';

    html.document.body?.children.add(iframe);

    iframe.onLoad.listen((_) {
      try {
        final contentWin = (iframe as dynamic).contentWindow;
        contentWin?.focus();
        contentWin?.print();
      } catch (_) {}
    });

    iframe.srcdoc = htmlContent;
  } catch (_) {}
}
