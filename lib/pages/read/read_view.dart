import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ReadView extends StatelessWidget {
  final EpubBook book;

  const ReadView(this.book, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.Title ?? '')),
      body: SafeArea(
        child: PageView.builder(
          itemBuilder: (context, index) {
            // return Text(
            //   book.Chapters![index + 1].HtmlContent ?? 'blank page',
            // );
            return InAppWebView(
              initialData: InAppWebViewInitialData(
                data: book.Chapters![index].HtmlContent ?? 'blank page',
              ),
            );
          },
        ),
      ),
    );
  }
}
