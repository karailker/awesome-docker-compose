from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
import os
import logging

app = FastAPI(title=os.getenv("APP_NAME", "FastAPI Example"))

logger = logging.getLogger("uvicorn")
handler = logging.FileHandler("/var/log/fastapi/app.log")
formatter = logging.Formatter("%(asctime)s %(levelname)s %(name)s - %(message)s")
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO)

class Item(BaseModel):
    id: int = Field(..., ge=1)
    name: str
    price: float = Field(..., ge=0)
    description: Optional[str] = None

@app.get("/")
def read_root():
    return {
        "app": os.getenv("APP_NAME", "FastAPI Example"),
        "env": os.getenv("APP_ENV", "production"),
        "message": "Hello from FastAPI!"
    }

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/items/{item_id}", response_model=Item)
def get_item(item_id: int):
    if item_id <= 0:
        raise HTTPException(status_code=400, detail="item_id must be positive")
    item = Item(id=item_id, name=f"Item-{item_id}", price=9.99)
    logger.info("get_item called with id=%s", item_id)
    return item

class EchoIn(BaseModel):
    text: str

class EchoOut(BaseModel):
    length: int
    upper: str

@app.post("/echo", response_model=EchoOut)
def echo(payload: EchoIn):
    txt = payload.text or ""
    logger.info("echo called")
    return EchoOut(length=len(txt), upper=txt.upper())
