"""Unit tests for ai_amb."""

import pytest
from ai_amb import Ai_amb

class TestAi_amb:
    """Test cases for Ai_amb class."""
    
    def test_create_instance(self):
        """Test instance creation."""
        app = Ai_amb()
        assert isinstance(app, Ai_amb)
    
    def test_greet(self):
        """Test greeting functionality."""
        app = Ai_amb()
        greeting = app.greet()
        assert "ai_amb" in greeting
        assert "AI_AGE_SDLC" in greeting
