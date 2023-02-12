import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

part 'download_state.dart';

class DownloadCubit extends Cubit<DownloadState> {
  DownloadCubit() : super(DownloadInitial());

  Future<void> download(String url, String filename) async {
    emit(Downloading());
    final dio = Dio(BaseOptions(followRedirects: true));
    try {
      final downloadUrl = parse((await Dio(BaseOptions(followRedirects: true)).get(url)).data)
          .getElementsByTagName('a')
          .firstWhere((a) => a.attributes['href'].toString().contains('get.php?'))
          .attributes['href'];

      final response = await dio.get(
        'https://libgen.rocks/${downloadUrl!}',
        onReceiveProgress: (received, total) {
          if (total != -1) {
            emit(DownloadProgress('${(received / total * 100).toStringAsFixed(0)}}%'));
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      final file = File('${(await getApplicationDocumentsDirectory()).path}/books/$filename.epub');

      await file.writeAsBytes(response.data);

      Share.shareXFiles([XFile(file.path)]);

      emit(Downloaded());
    } catch (e) {
      emit(DownloadError());
      debugPrint(e.toString());
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      emit(DownloadInitial());
    }
  }
}
