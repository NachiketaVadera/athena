part of 'download_cubit.dart';

@immutable
abstract class DownloadState {}

class DownloadInitial extends DownloadState {}

class Downloading extends DownloadState {}

class DownloadProgress extends DownloadState {
  final String progress;
  DownloadProgress(this.progress);
}

class Downloaded extends DownloadState {}

class DownloadError extends DownloadState {}
