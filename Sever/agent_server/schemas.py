from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel, Field


class Category(BaseModel):
    id: str
    name: str
    summary: str
    icon: str


class Recommendation(BaseModel):
    id: str
    title: str
    subtitle: str
    tags: List[str] = Field(default_factory=list)
    score: float


class BootstrapResponse(BaseModel):
    welcome_message: str
    prompt_hint: str
    recommendations: List[Recommendation]


class AskRequest(BaseModel):
    category_id: Optional[str] = None
    message: str


class AskResponse(BaseModel):
    assistant_message: str
    recommendations: List[Recommendation]
