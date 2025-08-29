"""
Response Generator Module for AMB Hallucination Prevention
Generates validated, hallucination-free responses
"""

import logging
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
import json

from .data_validator import DataValidator
from .logic_checker import LogicChecker

logger = logging.getLogger(__name__)


class ResponseGenerator:
    """
    Generates responses with built-in hallucination prevention
    """
    
    def __init__(self, confidence_threshold: float = 0.85):
        """
        Initialize ResponseGenerator
        
        Args:
            confidence_threshold: Minimum confidence for acceptable responses
        """
        if not 0 <= confidence_threshold <= 1:
            raise ValueError("Confidence threshold must be between 0 and 1")
        
        self.confidence_threshold = confidence_threshold
        self.data_validator = DataValidator(confidence_threshold)
        self.logic_checker = LogicChecker()
        self.response_cache = {}
        self.generation_stats = {"total": 0, "successful": 0, "rejected": 0}
        logger.info(f"ResponseGenerator initialized with threshold: {confidence_threshold}")
    
    def generate_response(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate a validated response for the request
        
        Args:
            request: Request dictionary containing query and context
            
        Returns:
            Response dictionary with content and metadata
        """
        try:
            if not request:
                logger.error("Empty request received")
                return self._create_error_response("Empty request")
            
            query = request.get("query", "")
            context = request.get("context", {})
            
            if not query:
                logger.warning("No query in request")
                return self._create_error_response("No query provided")
            
            # Generate raw response
            raw_response = self._generate_raw_response(query, context)
            
            # Validate response
            validation_result = self._validate_response(raw_response)
            
            if not validation_result["valid"]:
                logger.warning(f"Response validation failed: {validation_result['errors']}")
                self.generation_stats["rejected"] += 1
                
                # Attempt regeneration with stricter constraints
                raw_response = self._regenerate_with_constraints(query, context, validation_result["errors"])
                validation_result = self._validate_response(raw_response)
                
                if not validation_result["valid"]:
                    return self._create_error_response("Could not generate valid response", validation_result["errors"])
            
            # Check logic consistency
            logic_result = self.logic_checker.check_response_logic(raw_response)
            
            if not logic_result["valid"]:
                logger.warning(f"Logic check failed: {logic_result['errors']}")
                self.generation_stats["rejected"] += 1
                return self._create_error_response("Logic inconsistency detected", logic_result["errors"])
            
            # Build final response
            final_response = self._build_final_response(raw_response, validation_result, logic_result)
            
            self.generation_stats["successful"] += 1
            self.generation_stats["total"] += 1
            
            logger.info(f"Response generated successfully with confidence: {final_response['confidence']:.2f}")
            
            return final_response
            
        except Exception as e:
            logger.error(f"Response generation error: {str(e)}")
            self.generation_stats["total"] += 1
            return self._create_error_response(f"Generation error: {str(e)}")
    
    def generate_batch_responses(self, requests: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Generate responses for multiple requests
        
        Args:
            requests: List of request dictionaries
            
        Returns:
            List of response dictionaries
        """
        if not requests:
            return []
        
        responses = []
        
        for request in requests:
            response = self.generate_response(request)
            responses.append(response)
        
        logger.info(f"Batch generation complete: {len(responses)} responses")
        
        return responses
    
    def validate_and_filter(self, content: str, source: str = "") -> Tuple[bool, str, float]:
        """
        Validate and filter content for hallucinations
        
        Args:
            content: Content to validate
            source: Source reference
            
        Returns:
            Tuple of (is_valid, filtered_content, confidence)
        """
        try:
            if not content:
                return False, "", 0.0
            
            # Validate with data validator
            is_valid, confidence, error = self.data_validator.validate_data_point(content, source)
            
            if not is_valid:
                logger.debug(f"Content validation failed: {error}")
                return False, "", confidence
            
            # Filter hallucination patterns
            filtered_content = self._filter_hallucination_patterns(content)
            
            # Check if filtering changed content significantly
            if len(filtered_content) < len(content) * 0.5:
                logger.warning("Filtering removed too much content")
                return False, filtered_content, confidence * 0.5
            
            return True, filtered_content, confidence
            
        except Exception as e:
            logger.error(f"Validation and filtering error: {str(e)}")
            return False, "", 0.0
    
    def _generate_raw_response(self, query: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate raw response before validation
        
        Args:
            query: User query
            context: Context information
            
        Returns:
            Raw response dictionary
        """
        # Simulate response generation (replace with actual model)
        response = {
            "content": f"Response to: {query}",
            "data": [],
            "metadata": {
                "timestamp": datetime.utcnow().isoformat(),
                "query": query,
                "context_provided": bool(context)
            }
        }
        
        # Add contextual data if available
        if context:
            response["data"] = self._extract_data_points(context)
        
        return response
    
    def _validate_response(self, response: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate response for hallucinations
        
        Args:
            response: Response to validate
            
        Returns:
            Validation result dictionary
        """
        errors = []
        warnings = []
        
        # Validate content
        content = response.get("content", "")
        if content:
            is_valid, filtered, confidence = self.validate_and_filter(content, "response_content")
            
            if not is_valid:
                errors.append(f"Content validation failed (confidence: {confidence:.2f})")
            else:
                response["content"] = filtered
        
        # Validate data points
        data_points = response.get("data", [])
        validated_data = []
        
        for point in data_points:
            validation = self.data_validator.validate_data_point(
                point.get("value"),
                point.get("source", "")
            )
            
            if validation[0]:  # is_valid
                validated_data.append(point)
            else:
                warnings.append(f"Data point rejected: {validation[2]}")
        
        response["data"] = validated_data
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
            "confidence": confidence if content else 1.0
        }
    
    def _regenerate_with_constraints(self, query: str, context: Dict[str, Any], errors: List[str]) -> Dict[str, Any]:
        """
        Regenerate response with additional constraints
        
        Args:
            query: Original query
            context: Context information
            errors: Previous validation errors
            
        Returns:
            Regenerated response
        """
        logger.info("Regenerating response with stricter constraints")
        
        # Add constraints based on errors
        constraints = {
            "avoid_patterns": self._extract_error_patterns(errors),
            "require_sources": True,
            "max_length": 500
        }
        
        # Generate new response with constraints
        response = self._generate_raw_response(query, context)
        
        # Apply additional filtering
        response["content"] = self._apply_strict_filtering(response.get("content", ""))
        
        return response
    
    def _filter_hallucination_patterns(self, content: str) -> str:
        """
        Filter known hallucination patterns from content
        
        Args:
            content: Content to filter
            
        Returns:
            Filtered content
        """
        if not content:
            return ""
        
        filtered = content
        
        # Remove common hallucination phrases
        hallucination_phrases = [
            "As an AI assistant",
            "I don't have access to",
            "I cannot provide",
            "[PLACEHOLDER]",
            "[INSERT HERE]"
        ]
        
        for phrase in hallucination_phrases:
            filtered = filtered.replace(phrase, "")
        
        # Clean up extra whitespace
        filtered = " ".join(filtered.split())
        
        return filtered
    
    def _extract_data_points(self, context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Extract data points from context
        
        Args:
            context: Context dictionary
            
        Returns:
            List of data point dictionaries
        """
        data_points = []
        
        for key, value in context.items():
            if value is not None:
                data_points.append({
                    "key": key,
                    "value": value,
                    "source": "context",
                    "timestamp": datetime.utcnow().isoformat()
                })
        
        return data_points
    
    def _extract_error_patterns(self, errors: List[str]) -> List[str]:
        """
        Extract patterns to avoid from errors
        
        Args:
            errors: List of error messages
            
        Returns:
            List of patterns to avoid
        """
        patterns = []
        
        for error in errors:
            if "hallucination" in error.lower():
                patterns.append("unsupported_claim")
            if "contradiction" in error.lower():
                patterns.append("contradictory_statement")
            if "confidence" in error.lower():
                patterns.append("low_confidence_assertion")
        
        return patterns
    
    def _apply_strict_filtering(self, content: str) -> str:
        """
        Apply strict filtering rules
        
        Args:
            content: Content to filter
            
        Returns:
            Strictly filtered content
        """
        if not content:
            return ""
        
        # Remove any uncertain language
        uncertain_phrases = [
            "might be",
            "could be",
            "possibly",
            "maybe",
            "I think",
            "I believe"
        ]
        
        filtered = content
        for phrase in uncertain_phrases:
            filtered = filtered.replace(phrase, "")
        
        return filtered.strip()
    
    def _build_final_response(self, raw_response: Dict[str, Any], 
                            validation_result: Dict[str, Any],
                            logic_result: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build final response with metadata
        
        Args:
            raw_response: Validated raw response
            validation_result: Validation results
            logic_result: Logic check results
            
        Returns:
            Final response dictionary
        """
        confidence_score = (
            validation_result.get("confidence", 0) * 0.5 +
            logic_result.get("consistency_score", 0) * 0.5
        )
        
        return {
            "success": True,
            "content": raw_response.get("content", ""),
            "data": raw_response.get("data", []),
            "confidence": confidence_score,
            "metadata": {
                "timestamp": datetime.utcnow().isoformat(),
                "validation_warnings": validation_result.get("warnings", []),
                "logic_warnings": logic_result.get("warnings", []),
                "generation_attempt": 1 if validation_result["valid"] else 2
            }
        }
    
    def _create_error_response(self, error_message: str, details: List[str] = None) -> Dict[str, Any]:
        """
        Create error response
        
        Args:
            error_message: Main error message
            details: Additional error details
            
        Returns:
            Error response dictionary
        """
        return {
            "success": False,
            "content": "",
            "data": [],
            "confidence": 0.0,
            "error": error_message,
            "error_details": details or [],
            "metadata": {
                "timestamp": datetime.utcnow().isoformat()
            }
        }
    
    def get_generation_stats(self) -> Dict[str, Any]:
        """
        Get response generation statistics
        
        Returns:
            Dictionary with generation statistics
        """
        total = self.generation_stats["total"]
        
        if total == 0:
            success_rate = 0.0
            rejection_rate = 0.0
        else:
            success_rate = self.generation_stats["successful"] / total
            rejection_rate = self.generation_stats["rejected"] / total
        
        return {
            "total_requests": total,
            "successful": self.generation_stats["successful"],
            "rejected": self.generation_stats["rejected"],
            "success_rate": success_rate,
            "rejection_rate": rejection_rate
        }