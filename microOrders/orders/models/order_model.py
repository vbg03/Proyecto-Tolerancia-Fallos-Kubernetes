from db.db import db
from datetime import datetime

class Orders(db.Model):
    __tablename__ = 'orders'

    id = db.Column(db.Integer, primary_key=True)
    userName = db.Column(db.String(255))
    userEmail = db.Column(db.String(255))
    saleTotal = db.Column(db.Numeric(10, 2))
    date = db.Column(db.DateTime, default=datetime.utcnow)

    def __init__(self, userName, userEmail, saleTotal):
        self.userName = userName
        self.userEmail = userEmail
        self.saleTotal = saleTotal