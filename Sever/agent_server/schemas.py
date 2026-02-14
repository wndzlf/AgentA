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


class ModeOption(BaseModel):
    id: str
    title: str
    description: str


class CategoryField(BaseModel):
    id: str
    label: str
    hint: str
    keywords: List[str] = Field(default_factory=list)


class CategorySchemaResponse(BaseModel):
    category_id: str
    mode: str
    required_fields: List[CategoryField] = Field(default_factory=list)
    examples: List[str] = Field(default_factory=list)


class BootstrapResponse(BaseModel):
    welcome_message: str
    prompt_hint: str
    active_mode: str
    modes: List[ModeOption]
    recommendations: List[Recommendation]


class AskRequest(BaseModel):
    category_id: Optional[str] = None
    mode: Optional[str] = "find"
    message: str


class AskResponse(BaseModel):
    assistant_message: str
    active_mode: str
    action_result: Optional[str] = None
    recommendations: List[Recommendation]
