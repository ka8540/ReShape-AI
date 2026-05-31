from fastapi import HTTPException, status


class AppError(HTTPException):
    pass


def unauthorized(detail: str = "Authentication required") -> AppError:
    return AppError(status_code=status.HTTP_401_UNAUTHORIZED, detail=detail)


def forbidden(detail: str = "Forbidden") -> AppError:
    return AppError(status_code=status.HTTP_403_FORBIDDEN, detail=detail)


def not_found(detail: str = "Not found") -> AppError:
    return AppError(status_code=status.HTTP_404_NOT_FOUND, detail=detail)


def bad_request(detail: str) -> AppError:
    return AppError(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)


def conflict(detail: str) -> AppError:
    return AppError(status_code=status.HTTP_409_CONFLICT, detail=detail)
