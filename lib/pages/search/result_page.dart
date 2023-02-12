import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:athena/bloc/download_cubit.dart';
import 'package:athena/models/book.dart';
import 'package:athena/pages/search/details_page.dart';

const prefix = 'https://libgen.is';

final infoProvider = FutureProvider.autoDispose.family<List<BookInfo>, String>((ref, query) async {
  final document = parse(
    (await Dio().get('$prefix/fiction/?q=${query.split(' ').join('+')}&&criteria=title&language=English&format=epub'))
        .data,
  );

  final futures = <Future<Response>>[];
  document.getElementsByTagName('a').forEach((element) async {
    final link = element.attributes['href'];
    if (link == null) return;
    if (link.startsWith('/fiction/') && RegExp(r'fiction/[A-Z0-9]{32}').hasMatch(link)) {
      futures.add(Dio().get('$prefix$link'));
    }
  });

  final results = await Future.wait(futures);

  final info = <BookInfo>[];

  for (final result in results..removeWhere((result) => result.data == null && result.data is! dom.Document)) {
    final detailsPage = parse(result.data!);

    final title = detailsPage.getElementsByClassName('record_title').first.text;
    final img = '$prefix${detailsPage.getElementsByClassName('record_side').first.children.first.attributes['src']}';
    final format = getItem(detailsPage, 'format');
    final size = getItem(detailsPage, 'file size');
    final publisher = getItem(detailsPage, 'publisher');
    final isbn = getItem(detailsPage, 'isbn');
    final year = getItem(detailsPage, 'year');

    String? url = detailsPage
        .getElementsByClassName('record_mirrors')
        .first
        .children
        .firstWhereOrNull((element) {
          return element.children.first.attributes['href'].toString().contains('libgen.lc/ads');
        })
        ?.children
        .first
        .attributes['href'];

    info.add(
      BookInfo(
        title: title,
        imgUrl: img,
        format: format,
        size: size,
        publisher: publisher,
        isbn: isbn,
        year: year,
        downloadUrl: url,
      ),
    );
  }

  return info;
});

class SearchResultPage extends ConsumerWidget {
  final String query;

  const SearchResultPage(this.query, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(infoProvider(query));
    return Scaffold(
      appBar: AppBar(title: Text(query)),
      body: config.when(
        data: (data) => ListBooksView(data),
        error: (error, stackTrace) {
          return Text(error.toString());
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class ListBooksView extends StatelessWidget {
  final List<BookInfo> titles;

  const ListBooksView(this.titles, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: titles.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final book = titles[index];

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: InkWell(
              onTap: () async {
                final paletteGenerator = await PaletteGenerator.fromImageProvider(
                  CachedNetworkImageProvider(book.imgUrl),
                );

                // ignore: use_build_context_synchronously
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => DownloadCubit(),
                      child: DetailsPage(bookInfo: book, palette: paletteGenerator),
                    ),
                    fullscreenDialog: true,
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Hero(
                      tag: book.imgUrl,
                      child: CachedNetworkImage(
                        imageUrl: book.imgUrl,
                        progressIndicatorBuilder: (_, __, downloadProgress) => Center(
                          child: IntrinsicHeight(
                            child: CircularProgressIndicator(value: downloadProgress.progress),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error, color: Colors.red)),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('format: ${book.format}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String getItem(dom.Document doc, String item) {
  try {
    return doc
        .getElementsByTagName('tr')
        .firstWhere((e) => e.children.first.text.toLowerCase().contains('$item:'))
        .children[1]
        .text;
  } catch (error) {
    debugPrint(error.toString());
    return 'unknown';
  }
}
