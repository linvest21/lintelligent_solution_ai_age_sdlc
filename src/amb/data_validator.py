"""
Data Validator Module for AMB Hallucination Prevention
Validates raw data to prevent hallucinations
"""

import re
import logging
from typing import Dict, Any, Tuple, Optional, List
from datetime import datetime
import hashlib

logger = logging.getLogger(__name__)


class DataValidator:
    """
    Validates data points against source truth to prevent raw data hallucination
    """
    
    def __init__(self, confidence_threshold: float = 0.85):
        """
        Initialize DataValidator
        
        Args:
            confidence_threshold: Minimum confidence score for valid data (0-1)
        """
        if not 0 <= confidence_threshold <= 1:
            raise ValueError("Confidence threshold must be between 0 and 1")
        
        self.confidence_threshold = confidence_threshold
        self.source_data_cache = {}
        self.validation_history = []
        logger.info(f"DataValidator initialized with threshold: {confidence_threshold}")
    
    def validate_data_point(self, data: Any, source_reference: str) -> Tuple[bool, float, Optional[str]]:
        """
        Validate a single data point against source reference
        
        Args:
            data: Data point to validate
            source_reference: Reference to source truth
            
        Returns:
            Tuple of (is_valid, confidence_score, error_message)
        """
        try:
            if data is None:
                logger.warning("Null data point received")
                return False, 0.0, "Data point is null"
            
            if not source_reference:
                logger.warning("No source reference provided")
                return False, 0.0, "Missing source reference"
            
            # Calculate confidence score based on data characteristics
            confidence = self._calculate_confidence(data, source_reference)
            
            # Check if confidence meets threshold
            is_valid = confidence >= self.confidence_threshold
            
            # Log validation result
            self._log_validation(data, source_reference, is_valid, confidence)
            
            if not is_valid:
                error_msg = f"Confidence {confidence:.2f} below threshold {self.confidence_threshold}"
                logger.warning(f"Data validation failed: {error_msg}")
                return False, confidence, error_msg
            
            logger.debug(f"Data validated successfully with confidence: {confidence}")
            return True, confidence, None
            
        except Exception as e:
            logger.error(f"Validation error: {str(e)}")
            return False, 0.0, f"Validation error: {str(e)}"
    
    def validate_batch(self, data_points: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Validate multiple data points in batch
        
        Args:
            data_points: List of data points with source references
            
        Returns:
            Dictionary with validation results
        """
        if not data_points:
            return {"valid": 0, "invalid": 0, "results": []}
        
        results = []
        valid_count = 0
        invalid_count = 0
        
        for point in data_points:
            data = point.get("data")
            source = point.get("source", "")
            
            is_valid, confidence, error = self.validate_data_point(data, source)
            
            if is_valid:
                valid_count += 1
            else:
                invalid_count += 1
            
            results.append({
                "data": data,
                "source": source,
                "valid": is_valid,
                "confidence": confidence,
                "error": error
            })
        
        logger.info(f"Batch validation complete: {valid_count} valid, {invalid_count} invalid")
        
        return {
            "valid": valid_count,
            "invalid": invalid_count,
            "results": results
        }
    
    def check_numeric_bounds(self, value: float, min_val: float, max_val: float) -> bool:
        """
        Check if numeric value is within reasonable bounds
        
        Args:
            value: Numeric value to check
            min_val: Minimum acceptable value
            max_val: Maximum acceptable value
            
        Returns:
            True if within bounds, False otherwise
        """
        try:
            if value is None:
                return False
            
            in_bounds = min_val <= float(value) <= max_val
            
            if not in_bounds:
                logger.warning(f"Value {value} outside bounds [{min_val}, {max_val}]")
            
            return in_bounds
            
        except (TypeError, ValueError) as e:
            logger.error(f"Numeric bounds check failed: {str(e)}")
            return False
    
    def detect_pattern_anomaly(self, data: str, expected_pattern: str) -> bool:
        """
        Detect if data matches expected pattern
        
        Args:
            data: Data string to check
            expected_pattern: Regex pattern to match
            
        Returns:
            True if pattern matches, False if anomaly detected
        """
        try:
            if not data or not expected_pattern:
                return False
            
            pattern = re.compile(expected_pattern)
            matches = bool(pattern.match(str(data)))
            
            if not matches:
                logger.warning(f"Pattern anomaly detected: {data} doesn't match {expected_pattern}")
            
            return matches
            
        except re.error as e:
            logger.error(f"Pattern matching error: {str(e)}")
            return False
    
    def _calculate_confidence(self, data: Any, source_reference: str) -> float:
        """
        Calculate confidence score for data validity
        
        Args:
            data: Data to evaluate
            source_reference: Source reference
            
        Returns:
            Confidence score between 0 and 1
        """
        confidence = 1.0
        
        # Reduce confidence for missing source
        if not source_reference:
            confidence *= 0.5
        
        # Reduce confidence for suspicious patterns
        data_str = str(data)
        
        # Check for common hallucination patterns
        hallucination_patterns = [
            r'(?i)as an ai',
            r'(?i)i cannot',
            r'(?i)i don\'t have access',
            r'\[PLACEHOLDER\]',
            r'\[INSERT.*HERE\]'
        ]
        
        for pattern in hallucination_patterns:
            if re.search(pattern, data_str):
                confidence *= 0.3
                logger.debug(f"Hallucination pattern detected: {pattern}")
        
        # Check data consistency
        if source_reference in self.source_data_cache:
            cached_hash = self.source_data_cache[source_reference]
            current_hash = hashlib.md5(data_str.encode()).hexdigest()
            
            if cached_hash != current_hash:
                confidence *= 0.7
                logger.debug("Data inconsistency with cache detected")
        
        # Ensure confidence stays within bounds
        confidence = max(0.0, min(1.0, confidence))
        
        return confidence
    
    def _log_validation(self, data: Any, source: str, is_valid: bool, confidence: float):
        """
        Log validation event for audit trail
        
        Args:
            data: Validated data
            source: Source reference
            is_valid: Validation result
            confidence: Confidence score
        """
        validation_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "data_hash": hashlib.md5(str(data).encode()).hexdigest(),
            "source": source,
            "valid": is_valid,
            "confidence": confidence
        }
        
        self.validation_history.append(validation_entry)
        
        # Keep history size manageable
        if len(self.validation_history) > 10000:
            self.validation_history = self.validation_history[-5000:]
    
    def get_validation_stats(self) -> Dict[str, Any]:
        """
        Get validation statistics
        
        Returns:
            Dictionary with validation statistics
        """
        if not self.validation_history:
            return {
                "total_validations": 0,
                "valid_count": 0,
                "invalid_count": 0,
                "average_confidence": 0.0
            }
        
        valid_count = sum(1 for v in self.validation_history if v["valid"])
        invalid_count = len(self.validation_history) - valid_count
        avg_confidence = sum(v["confidence"] for v in self.validation_history) / len(self.validation_history)
        
        return {
            "total_validations": len(self.validation_history),
            "valid_count": valid_count,
            "invalid_count": invalid_count,
            "average_confidence": avg_confidence
        }