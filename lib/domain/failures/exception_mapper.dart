import '../exceptions/auth_exception.dart';
import '../exceptions/saber_exception.dart';
import '../exceptions/relato_exception.dart';
import '../exceptions/evento_exception.dart';
import '../exceptions/categoria_exception.dart';
import '../validators/contenido_validator.dart';
import 'failures.dart';

/// Mapea excepciones del dominio a la jerarquía unificada de Failure.
Failure mapExceptionToFailure(Object error) {
  switch (error) {
    // Validaciones genéricas
    case ContenidoValidationException e:
      return ValidationFailure(
        e.message,
        details: {'errores': e.errores},
      );

    // Autenticación / permisos
    case InvalidCredentialsException e:
      return ValidationFailure(e.message, code: e.code);
    case WeakPasswordException e:
      return ValidationFailure(e.message, code: e.code);
    case EmailAlreadyInUseException e:
      return ValidationFailure(e.message, code: e.code);
    case EmailNotVerifiedException e:
      return ValidationFailure(e.message, code: e.code);
    case UserNotFoundException e:
      return NotFoundFailure(e.message, code: e.code);
    case InsufficientPermissionsException e:
      return PermissionDeniedFailure(e.message, code: e.code);
    case AccountDisabledException e:
      return PermissionDeniedFailure(e.message, code: e.code);
    case SessionExpiredException e:
      return PermissionDeniedFailure(e.message, code: e.code);
    case NetworkException e:
      return NetworkFailure(e.message, code: e.code);

    // Saberes
    case SaberNotFoundException e:
      return NotFoundFailure(e.message, code: e.code, details: e.value);
    case SaberPermissionException e:
      return PermissionDeniedFailure(e.message, code: e.code, details: e.value);
    case SaberInvalidContentException e:
      return ValidationFailure(e.message, code: e.code, details: e.value);
    case SaberMediaException e:
      return ValidationFailure(e.message, code: e.code, details: e.value);
    case SaberLocationException e:
      return ValidationFailure(e.message, code: e.code, details: e.value);
    case SaberDuplicadoException e:
      return ValidationFailure(e.message, code: e.code, details: e.value);
    case SaberAlreadyReportedException e:
      return ValidationFailure(e.message, code: e.code, details: e.value);
    case SaberAlreadyDeletedException e:
      return ValidationFailure(e.message, code: e.code, details: e.value);
    case SaberNotDeletedException e:
      return ValidationFailure(e.message, code: e.code, details: e.value);
    case SaberModerationException e:
      return ValidationFailure(e.message, code: e.code, details: e.value);
    case SaberPopularException e:
      return ValidationFailure(e.message, code: e.code, details: e.value);

    // Relatos
    case RelatoNotFoundException e:
      return NotFoundFailure(e.message, code: e.code, details: e.value);
    case RelatoPermissionException e:
      return PermissionDeniedFailure(e.message, code: e.code, details: e.value);
    case RelatoInvalidContentException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case RelatoMediaException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case RelatoLocationException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case RelatoModerationException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case RelatoAlreadyReportedException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case RelatoAlreadyDeletedException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);

    // Eventos
    case EventoNotFoundException e:
      return NotFoundFailure(e.message, code: e.code, details: (e as dynamic).value);
    case SugerenciaNotFoundException e:
      return NotFoundFailure(e.message, code: e.code, details: (e as dynamic).value);
    case EventoPermissionException e:
      return PermissionDeniedFailure(e.message, code: e.code, details: e.value);
    case EventoInvalidContentException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case EventoInvalidDateException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case EventoLocationException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case EventoMediaException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case EventoDuplicadoException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case SugerenciaProcessException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case EventoAlreadyDeletedException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case EventoNotDeletedException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);

    // Categorías
    case CategoriaNotFoundException e:
      return NotFoundFailure(e.message, code: e.code, details: e.value);
    case CategoriaDuplicadaException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case CategoriaEnUsoException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case CategoriaValidationException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);
    case CategoriaHierarchyException e:
      return ValidationFailure(e.message, code: e.code, details: (e as dynamic).value);

    // Fallback
    default:
      return UnexpectedFailure(error.toString(), details: error);
  }
}


