import 'dart:io';

import 'package:athena/pages/read/read_view.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final booksProvider = FutureProvider.autoDispose<List<epubx.EpubBook>>(
  (ref) async {
    final directory = Directory('${(await getApplicationDocumentsDirectory()).path}/books')..create();

    final files = await Future.wait(directory.listSync().map((e) => File(e.path).readAsBytes()));
    final books = await Future.wait(files.map((f) => epubx.EpubReader.readBook(f)));

    return books;
  },
);

class ReadHome extends ConsumerWidget {
  const ReadHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Expanded(
              child: books.when<Widget>(
                loading: () => const Center(child: CircularProgressIndicator()),
                data: (data) => _ListView(data),
                error: (error, stackTrace) => Text(error.toString()),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  Feedback.forTap(context);

                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    allowedExtensions: ['.epub'],
                    dialogTitle: 'add to your library',
                    type: FileType.custom,
                  );

                  if (result != null) {
                    final directory = '${(await getApplicationDocumentsDirectory()).path}/books';

                    await Future.wait(
                      result.files
                          .map((pf) => File(pf.path!))
                          .map((f) => f.copy('$directory/${f.path.split('/').last}')),
                    );

                    ref.invalidate(booksProvider);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('add book'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<epubx.EpubBook> books;
  const _ListView(this.books);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: .6,
      children: [
        for (final book in books) ...[
          Card(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => ReadView(book),
                    fullscreenDialog: true,
                  ),
                );
              },
              onLongPress: () {
                Share.shareXFiles([]);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Expanded(
                      child: book.CoverImage != null
                          ? Image.memory(Uint8List.fromList(image.encodePng(book.CoverImage!)))
                          : const Icon(Icons.error_rounded, color: Colors.red),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        book.Title ?? 'Untitled',
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'by ${book.Author ?? book.AuthorList?[0] ?? 'Unknown'}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
