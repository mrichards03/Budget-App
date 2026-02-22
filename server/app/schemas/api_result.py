from typing import Generic, TypeVar, Optional

T = TypeVar('T')

class ApiResult(Generic[T]):
    def __init__(self, data: Optional[T] = None, error: Optional[str] = None):
        self.data = data
        self.error = error

    @property
    def is_success(self) -> bool:
        return self.error is None

    @classmethod
    def success(cls, data: T = None):
        return cls(data=data)

    @classmethod
    def error(cls, error: str):
        return cls(error=error)
