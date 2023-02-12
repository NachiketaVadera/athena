part of 'download_cubit.dart';

@immutable
abstract class DownloadState {}

class DownloadInitial extends DownloadState {}

class Downloading extends DownloadState {}

class DownloadInProgress extends DownloadState {
  final String progress;
  DownloadInProgress(this.progress);
}

class Downloaded extends DownloadState {}

class DownloadError extends DownloadState {}
