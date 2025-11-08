import os

class Config:
    MYSQL_HOST = 'localhost'
    MYSQL_USER = 'root'
    MYSQL_PASSWORD = 'root'
    MYSQL_DB = 'myflaskapp'
    SQLALCHEMY_DATABASE_URI = f"mysql+mysqlconnector://{os.getenv('DATABASE_USER')}:{os.getenv('DATABASE_PASSWORD')}@{os.getenv('DATABASE_HOST')}/{os.getenv('DATABASE_NAME')}"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
