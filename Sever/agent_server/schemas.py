from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel, Field


class Category(BaseModel):
    id: str
    name: str
    summary: str
    icon: str
    domain: str = ""
    focus: str = ""


class Recommendation(BaseModel):
    id: str
    title: str
    subtitle: str
    tags: List[str] = Field(default_factory=list)
    score: float
    detail: str = ""
    image_urls: List[str] = Field(default_factory=list)
    owner_name: str = ""
    owner_email_masked: str = ""
    owner_phone_masked: str = ""


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


class RouteRequest(BaseModel):
    message: str
    limit: int = 5


class RouteCandidate(BaseModel):
    category_id: str
    category_name: str
    domain: str
    score: float
    reason: str
    suggested_mode: str


class RouteResponse(BaseModel):
    selected: Optional[RouteCandidate] = None
    candidates: List[RouteCandidate] = Field(default_factory=list)


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
    user_email: Optional[str] = None
    user_name: Optional[str] = None
    target_recommendation_id: Optional[str] = None


class AskResponse(BaseModel):
    assistant_message: str
    active_mode: str
    action_result: Optional[str] = None
    recommendations: List[Recommendation]


class ActionHistoryItem(BaseModel):
    status: str
    note: Optional[str] = None
    at: str


class MatchAction(BaseModel):
    id: str
    category_id: str
    recommendation_id: str
    recommendation_title: str
    recommendation_subtitle: str = ""
    status: str
    actor_role: str = "viewer"
    requester_email: str = ""
    requester_name: str = ""
    owner_email_masked: str = ""
    allowed_actions: List[str] = Field(default_factory=list)
    contact_unlocked: bool = False
    counterpart_name: Optional[str] = None
    counterpart_email: Optional[str] = None
    counterpart_phone: Optional[str] = None
    note: Optional[str] = None
    created_at: str
    updated_at: str
    history: List[ActionHistoryItem] = Field(default_factory=list)


class ActionCreateRequest(BaseModel):
    category_id: Optional[str] = None
    recommendation_id: str
    recommendation_title: str
    recommendation_subtitle: str = ""
    requester_email: str
    requester_name: Optional[str] = None
    note: Optional[str] = None


class ActionTransitionRequest(BaseModel):
    action: str
    actor_email: str
    note: Optional[str] = None


class ActionListResponse(BaseModel):
    actions: List[MatchAction] = Field(default_factory=list)


class RecommendationDetailResponse(BaseModel):
    recommendation: Recommendation
    action: Optional[MatchAction] = None


class MyListingItem(BaseModel):
    category_id: str
    category_name: str
    recommendation: Recommendation
    created_at: str
    updated_at: str


class MyListingsResponse(BaseModel):
    listings: List[MyListingItem] = Field(default_factory=list)


class EmailAuthRequest(BaseModel):
    email: str
    name: Optional[str] = None


class EmailAuthResponse(BaseModel):
    email: str
    name: str
    created: bool
