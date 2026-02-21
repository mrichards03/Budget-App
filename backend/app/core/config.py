from pydantic_settings import BaseSettings
from pydantic import Field

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = Field(default="sqlite:///./budget_app.db")
        
    # Application
    API_VERSION: str = Field(default="v1")
    DEBUG: bool = Field(default=True)
    
    # ML Models
    MODEL_PATH: str = Field(default="./ml_models/saved_models/")
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
