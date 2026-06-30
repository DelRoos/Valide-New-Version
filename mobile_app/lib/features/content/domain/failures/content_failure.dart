import '../../../../core/error/failures.dart';

enum ContentFailureKind { networkUnavailable, permissionDenied, notFound, unknown }

sealed class ContentFailure extends Failure {
  const ContentFailure(super.message);

  const factory ContentFailure.networkError(String message) =
      _ContentNetworkFailure;
  const factory ContentFailure.permissionDenied() = _ContentPermissionFailure;
  const factory ContentFailure.notFound(String id) = _ContentNotFoundFailure;
  const factory ContentFailure.unknown(String message) = _ContentUnknownFailure;

  ContentFailureKind get kind;
}

class _ContentNetworkFailure extends ContentFailure {
  const _ContentNetworkFailure(super.message);

  @override
  ContentFailureKind get kind => ContentFailureKind.networkUnavailable;

  @override
  List<Object?> get props => [kind, message];
}

class _ContentPermissionFailure extends ContentFailure {
  const _ContentPermissionFailure()
      : super('Accès refusé — session expirée ou droits insuffisants');

  @override
  ContentFailureKind get kind => ContentFailureKind.permissionDenied;

  @override
  List<Object?> get props => [kind];
}

class _ContentNotFoundFailure extends ContentFailure {
  const _ContentNotFoundFailure(this.id) : super('Document introuvable : $id');

  final String id;

  @override
  ContentFailureKind get kind => ContentFailureKind.notFound;

  @override
  List<Object?> get props => [kind, id];
}

class _ContentUnknownFailure extends ContentFailure {
  const _ContentUnknownFailure(super.message);

  @override
  ContentFailureKind get kind => ContentFailureKind.unknown;

  @override
  List<Object?> get props => [kind, message];
}
