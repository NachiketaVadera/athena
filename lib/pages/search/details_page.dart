import 'package:athena/bloc/download_cubit.dart';
import 'package:athena/models/book.dart';
import 'package:cached_network_image/cached_network_image.dart' as cni;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class DetailsPage extends StatelessWidget {
  final BookInfo bookInfo;
  final PaletteGenerator palette;

  late final controller = RoundedLoadingButtonController();

  DetailsPage({super.key, required this.bookInfo, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: Navigator.of(context).pop,
          icon: Icon(Icons.close_rounded, color: foreground),
        ),
        backgroundColor: palette.dominantColor?.color,
        title: Text('details', style: TextStyle(color: foreground)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // * ====== hero
                SizedBox(
                  height: 300,
                  child: Hero(
                    tag: bookInfo.imgUrl,
                    child: cni.CachedNetworkImage(
                      imageUrl: bookInfo.imgUrl,
                      progressIndicatorBuilder: (_, __, progress) =>
                          CircularProgressIndicator(value: progress.progress),
                      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error, color: Colors.red)),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // * ====== title
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: Text(
                    bookInfo.title,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),

                // * ====== details
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Table(
                    children: [
                      _row('format', bookInfo.format),
                      _row('year', bookInfo.year),
                      _row('isbn', bookInfo.isbn),
                      _row('publisher', bookInfo.publisher),
                      _row('size', bookInfo.size),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: BlocBuilder<DownloadCubit, DownloadState>(
                    builder: (context, state) {
                      if (state is DownloadProgress) {
                        return Center(
                          child: Text(
                            'downlading\n${state.progress}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocConsumer<DownloadCubit, DownloadState>(
        listener: (context, state) {
          if (state is DownloadError) {
            controller.error();
            context.notify('failed to download book');
          } else if (state is Downloading) {
            controller.start();
          } else if (state is Downloaded) {
            controller.success();
          } else if (state is DownloadInitial) {
            controller.reset();
          }
        },
        builder: (context, state) {
          return RoundedLoadingButton(
            controller: controller,
            successColor: Colors.green,
            errorColor: Colors.red,
            onPressed: () {
              debugPrint(bookInfo.downloadUrl);
              if (bookInfo.downloadUrl != null) {
                context.read<DownloadCubit>().download(bookInfo.downloadUrl!, bookInfo.title);
              } else {
                context.notify('unable to download book');
              }
            },
            color: palette.dominantColor?.color,
            child: Icon(Icons.download, color: foreground),
          );
        },
      ),
    );
  }

  Color get foreground {
    if (palette.dominantColor == null) return Colors.white;
    return (palette.dominantColor!.color.computeLuminance() > 0.179) ? Colors.black : Colors.white;
  }

  TableRow _row(String header, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(header, textAlign: TextAlign.left),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(value, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

extension on BuildContext {
  void notify(String text) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(text)));
  }
}
