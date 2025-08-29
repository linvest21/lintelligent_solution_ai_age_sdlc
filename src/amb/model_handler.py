"""
Model Handler Module for AMB Hallucination Prevention
Main orchestrator for the AMB system with hallucination prevention
"""

import logging
import json
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
import time

from .data_validator import DataValidator
from .logic_checker import LogicChecker
from .response_generator import ResponseGenerator

logger = logging.getLogger(__name__)


class ModelHandler:
    """
    Main handler for AMB model with integrated hallucination prevention
    """
    
    def __init__(self, config: Dict[str, Any] = None):
        """
        Initialize ModelHandler
        
        Args:
            config: Configuration dictionary
        """
        self.config = config or self._get_default_config()
        
        # Validate configuration
        self._validate_config()
        
        # Initialize components
        confidence_threshold = self.config.get("confidence_threshold", 0.85)
        self.data_validator = DataValidator(confidence_threshold)
        self.logic_checker = LogicChecker(self.config.get("context_window", 100))
        self.response_generator = ResponseGenerator(confidence_threshold)
        
        # Performance tracking
        self.performance_metrics = {
            "total_requests": 0,
            "successful_requests": 0,
            "failed_requests": 0,
            "hallucinations_prevented": 0,
            "total_response_time": 0.0
        }
        
        # Hallucination tracking
        self.hallucination_logs = []
        
        logger.info("ModelHandler initialized with hallucination prevention")
    
    def process_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process a request with full hallucination prevention
        
        Args:
            request: Request dictionary
            
        Returns:
            Response dictionary with validated content
        """
        start_time = time.time()
        request_id = self._generate_request_id()
        
        try:
            logger.info(f"Processing request {request_id}")
            
            if not request:
                logger.error(f"Empty request {request_id}")
                return self._create_error_response("Empty request", request_id)
            
            # Pre-process and validate input
            validated_input = self._preprocess_input(request)
            
            if not validated_input["valid"]:
                logger.warning(f"Input validation failed for {request_id}")
                self.performance_metrics["failed_requests"] += 1
                return self._create_error_response("Input validation failed", request_id, validated_input["errors"])
            
            # Generate response with hallucination prevention
            response = self.response_generator.generate_response(validated_input["processed_request"])
            
            # Post-process response
            final_response = self._postprocess_response(response, request_id)
            
            # Track performance
            response_time = time.time() - start_time
            self._update_metrics(response_time, final_response["success"])
            
            # Check response time against threshold
            if response_time > self.config.get("max_response_time_ms", 200) / 1000:
                logger.warning(f"Response time {response_time:.3f}s exceeded threshold for {request_id}")
            
            logger.info(f"Request {request_id} processed successfully in {response_time:.3f}s")
            
            return final_response
            
        except Exception as e:
            logger.error(f"Error processing request {request_id}: {str(e)}")
            self.performance_metrics["failed_requests"] += 1
            return self._create_error_response(f"Processing error: {str(e)}", request_id)
    
    def batch_process(self, requests: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Process multiple requests in batch
        
        Args:
            requests: List of request dictionaries
            
        Returns:
            List of response dictionaries
        """
        if not requests:
            return []
        
        logger.info(f"Processing batch of {len(requests)} requests")
        
        responses = []
        for request in requests:
            response = self.process_request(request)
            responses.append(response)
        
        # Calculate batch statistics
        successful = sum(1 for r in responses if r.get("success", False))
        failed = len(responses) - successful
        
        logger.info(f"Batch processing complete: {successful} successful, {failed} failed")
        
        return responses
    
    def detect_hallucination(self, content: str, context: Dict[str, Any] = None) -> Tuple[bool, float, str]:
        """
        Detect potential hallucination in content
        
        Args:
            content: Content to check
            context: Optional context for validation
            
        Returns:
            Tuple of (has_hallucination, confidence, detection_reason)
        """
        try:
            if not content:
                return True, 1.0, "Empty content"
            
            # Check with data validator
            source = context.get("source", "") if context else ""
            is_valid, confidence, error = self.data_validator.validate_data_point(content, source)
            
            if not is_valid:
                self._log_hallucination(content, "data_validation", error)
                return True, 1.0 - confidence, error or "Failed data validation"
            
            # Check logic consistency
            is_consistent, contradictions = self.logic_checker.check_statement_consistency(content)
            
            if not is_consistent:
                reason = "; ".join(contradictions)
                self._log_hallucination(content, "logic_inconsistency", reason)
                return True, 0.9, reason
            
            # Pattern-based detection
            hallucination_detected, pattern_confidence, pattern_reason = self._detect_hallucination_patterns(content)
            
            if hallucination_detected:
                self._log_hallucination(content, "pattern_match", pattern_reason)
                return True, pattern_confidence, pattern_reason
            
            return False, confidence, "No hallucination detected"
            
        except Exception as e:
            logger.error(f"Hallucination detection error: {str(e)}")
            return True, 0.5, f"Detection error: {str(e)}"
    
    def _preprocess_input(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Preprocess and validate input request
        
        Args:
            request: Raw request
            
        Returns:
            Validation result with processed request
        """
        errors = []
        
        # Extract and validate query
        query = request.get("query", "").strip()
        if not query:
            errors.append("Missing or empty query")
        
        # Validate query doesn't contain injection attempts
        if self._detect_injection(query):
            errors.append("Potential injection detected in query")
        
        # Extract and validate context
        context = request.get("context", {})
        if context and not isinstance(context, dict):
            errors.append("Context must be a dictionary")
        
        # Build processed request
        processed_request = {
            "query": query,
            "context": context,
            "metadata": request.get("metadata", {}),
            "timestamp": datetime.utcnow().isoformat()
        }
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "processed_request": processed_request if not errors else None
        }
    
    def _postprocess_response(self, response: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """
        Post-process response before returning
        
        Args:
            response: Generated response
            request_id: Request identifier
            
        Returns:
            Final processed response
        """
        # Add request ID
        response["request_id"] = request_id
        
        # Add hallucination prevention metadata
        response["hallucination_prevention"] = {
            "enabled": True,
            "confidence_threshold": self.config.get("confidence_threshold", 0.85),
            "checks_performed": ["data_validation", "logic_consistency", "pattern_detection"]
        }
        
        # Track if hallucination was prevented
        if not response.get("success", False):
            error = response.get("error", "")
            if "hallucination" in error.lower() or "validation" in error.lower():
                self.performance_metrics["hallucinations_prevented"] += 1
        
        return response
    
    def _detect_hallucination_patterns(self, content: str) -> Tuple[bool, float, str]:
        """
        Detect hallucination using pattern matching
        
        Args:
            content: Content to check
            
        Returns:
            Tuple of (detected, confidence, reason)
        """
        patterns = [
            {
                "pattern": r"(?i)as an ai|as a language model",
                "confidence": 0.95,
                "reason": "Self-referential AI pattern"
            },
            {
                "pattern": r"(?i)i don't have access|cannot access",
                "confidence": 0.9,
                "reason": "Access limitation pattern"
            },
            {
                "pattern": r"\[.*?\]|\{.*?\}",
                "confidence": 0.8,
                "reason": "Placeholder pattern"
            },
            {
                "pattern": r"(?i)hypothetically|theoretically|in theory",
                "confidence": 0.7,
                "reason": "Speculative language pattern"
            }
        ]
        
        import re
        
        for pattern_info in patterns:
            if re.search(pattern_info["pattern"], content):
                return True, pattern_info["confidence"], pattern_info["reason"]
        
        return False, 0.0, ""
    
    def _detect_injection(self, text: str) -> bool:
        """
        Detect potential injection attempts
        
        Args:
            text: Text to check
            
        Returns:
            True if injection pattern detected
        """
        injection_patterns = [
            r"<script",
            r"javascript:",
            r"on\w+\s*=",
            r"eval\s*\(",
            r"DROP\s+TABLE",
            r"DELETE\s+FROM",
            r"INSERT\s+INTO"
        ]
        
        import re
        
        for pattern in injection_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                logger.warning(f"Potential injection detected: {pattern}")
                return True
        
        return False
    
    def _log_hallucination(self, content: str, detection_type: str, reason: str):
        """
        Log detected hallucination
        
        Args:
            content: Hallucinated content
            detection_type: Type of detection
            reason: Reason for detection
        """
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "content_snippet": content[:100] if len(content) > 100 else content,
            "detection_type": detection_type,
            "reason": reason
        }
        
        self.hallucination_logs.append(log_entry)
        
        # Keep log size manageable
        if len(self.hallucination_logs) > 1000:
            self.hallucination_logs = self.hallucination_logs[-500:]
        
        logger.info(f"Hallucination detected and prevented: {detection_type} - {reason}")
    
    def _update_metrics(self, response_time: float, success: bool):
        """
        Update performance metrics
        
        Args:
            response_time: Time taken to process request
            success: Whether request was successful
        """
        self.performance_metrics["total_requests"] += 1
        self.performance_metrics["total_response_time"] += response_time
        
        if success:
            self.performance_metrics["successful_requests"] += 1
        else:
            self.performance_metrics["failed_requests"] += 1
    
    def _generate_request_id(self) -> str:
        """
        Generate unique request ID
        
        Returns:
            Request ID string
        """
        import uuid
        return f"req_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{str(uuid.uuid4())[:8]}"
    
    def _create_error_response(self, error_message: str, request_id: str, details: List[str] = None) -> Dict[str, Any]:
        """
        Create error response
        
        Args:
            error_message: Main error message
            request_id: Request identifier
            details: Additional error details
            
        Returns:
            Error response dictionary
        """
        return {
            "success": False,
            "request_id": request_id,
            "content": "",
            "data": [],
            "confidence": 0.0,
            "error": error_message,
            "error_details": details or [],
            "metadata": {
                "timestamp": datetime.utcnow().isoformat()
            }
        }
    
    def _validate_config(self):
        """
        Validate configuration parameters
        """
        required_keys = ["confidence_threshold", "context_window", "max_response_time_ms"]
        
        for key in required_keys:
            if key not in self.config:
                logger.warning(f"Missing config key: {key}, using default")
        
        # Validate confidence threshold
        threshold = self.config.get("confidence_threshold", 0.85)
        if not 0 <= threshold <= 1:
            raise ValueError(f"Invalid confidence threshold: {threshold}")
        
        # Validate context window
        window = self.config.get("context_window", 100)
        if window <= 0:
            raise ValueError(f"Invalid context window: {window}")
    
    def _get_default_config(self) -> Dict[str, Any]:
        """
        Get default configuration
        
        Returns:
            Default configuration dictionary
        """
        return {
            "confidence_threshold": 0.85,
            "context_window": 100,
            "max_response_time_ms": 200,
            "enable_caching": True,
            "cache_ttl_seconds": 300,
            "max_retries": 2
        }
    
    def get_performance_metrics(self) -> Dict[str, Any]:
        """
        Get performance metrics
        
        Returns:
            Performance metrics dictionary
        """
        total = self.performance_metrics["total_requests"]
        
        if total == 0:
            avg_response_time = 0.0
            success_rate = 0.0
            hallucination_prevention_rate = 0.0
        else:
            avg_response_time = self.performance_metrics["total_response_time"] / total
            success_rate = self.performance_metrics["successful_requests"] / total
            hallucination_prevention_rate = self.performance_metrics["hallucinations_prevented"] / total
        
        return {
            "total_requests": total,
            "successful_requests": self.performance_metrics["successful_requests"],
            "failed_requests": self.performance_metrics["failed_requests"],
            "hallucinations_prevented": self.performance_metrics["hallucinations_prevented"],
            "average_response_time_ms": avg_response_time * 1000,
            "success_rate": success_rate,
            "hallucination_prevention_rate": hallucination_prevention_rate,
            "recent_hallucinations": self.hallucination_logs[-10:]
        }
    
    def reset_metrics(self):
        """
        Reset performance metrics
        """
        self.performance_metrics = {
            "total_requests": 0,
            "successful_requests": 0,
            "failed_requests": 0,
            "hallucinations_prevented": 0,
            "total_response_time": 0.0
        }
        
        logger.info("Performance metrics reset")