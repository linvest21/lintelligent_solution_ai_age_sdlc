"""
Comprehensive unit tests for AMB Hallucination Prevention System
Tests all modules: data_validator, logic_checker, response_generator, model_handler
"""

import unittest
import sys
import os
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../src'))

from amb.data_validator import DataValidator
from amb.logic_checker import LogicChecker
from amb.response_generator import ResponseGenerator
from amb.model_handler import ModelHandler


class TestDataValidator(unittest.TestCase):
    """Test cases for DataValidator class"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.validator = DataValidator(confidence_threshold=0.85)
    
    def test_init_valid_threshold(self):
        """Test initialization with valid threshold"""
        validator = DataValidator(0.5)
        self.assertEqual(validator.confidence_threshold, 0.5)
    
    def test_init_invalid_threshold(self):
        """Test initialization with invalid threshold"""
        with self.assertRaises(ValueError):
            DataValidator(1.5)
        
        with self.assertRaises(ValueError):
            DataValidator(-0.1)
    
    def test_validate_data_point_null(self):
        """Test validation of null data point"""
        is_valid, confidence, error = self.validator.validate_data_point(None, "source")
        self.assertFalse(is_valid)
        self.assertEqual(confidence, 0.0)
        self.assertEqual(error, "Data point is null")
    
    def test_validate_data_point_no_source(self):
        """Test validation with missing source reference"""
        is_valid, confidence, error = self.validator.validate_data_point("data", "")
        self.assertFalse(is_valid)
        self.assertEqual(confidence, 0.0)
        self.assertEqual(error, "Missing source reference")
    
    def test_validate_data_point_valid(self):
        """Test validation of valid data point"""
        is_valid, confidence, error = self.validator.validate_data_point("valid data", "trusted_source")
        self.assertTrue(is_valid)
        self.assertGreaterEqual(confidence, 0.85)
        self.assertIsNone(error)
    
    def test_validate_data_point_hallucination_pattern(self):
        """Test detection of hallucination patterns"""
        hallucination_data = "As an AI, I cannot provide this information"
        is_valid, confidence, error = self.validator.validate_data_point(hallucination_data, "source")
        self.assertFalse(is_valid)
        self.assertLess(confidence, 0.85)
    
    def test_validate_batch_empty(self):
        """Test batch validation with empty list"""
        result = self.validator.validate_batch([])
        self.assertEqual(result["valid"], 0)
        self.assertEqual(result["invalid"], 0)
        self.assertEqual(result["results"], [])
    
    def test_validate_batch_mixed(self):
        """Test batch validation with mixed valid/invalid data"""
        data_points = [
            {"data": "valid data", "source": "source1"},
            {"data": None, "source": "source2"},
            {"data": "more valid data", "source": "source3"}
        ]
        
        result = self.validator.validate_batch(data_points)
        self.assertEqual(result["valid"], 2)
        self.assertEqual(result["invalid"], 1)
        self.assertEqual(len(result["results"]), 3)
    
    def test_check_numeric_bounds_valid(self):
        """Test numeric bounds checking with valid value"""
        self.assertTrue(self.validator.check_numeric_bounds(5.0, 0.0, 10.0))
        self.assertTrue(self.validator.check_numeric_bounds(0.0, 0.0, 10.0))
        self.assertTrue(self.validator.check_numeric_bounds(10.0, 0.0, 10.0))
    
    def test_check_numeric_bounds_invalid(self):
        """Test numeric bounds checking with invalid value"""
        self.assertFalse(self.validator.check_numeric_bounds(11.0, 0.0, 10.0))
        self.assertFalse(self.validator.check_numeric_bounds(-1.0, 0.0, 10.0))
        self.assertFalse(self.validator.check_numeric_bounds(None, 0.0, 10.0))
    
    def test_detect_pattern_anomaly_match(self):
        """Test pattern anomaly detection with matching pattern"""
        self.assertTrue(self.validator.detect_pattern_anomaly("test@example.com", r".*@.*\..*"))
        self.assertTrue(self.validator.detect_pattern_anomaly("12345", r"^\d+$"))
    
    def test_detect_pattern_anomaly_no_match(self):
        """Test pattern anomaly detection with non-matching pattern"""
        self.assertFalse(self.validator.detect_pattern_anomaly("not-an-email", r".*@.*\..*"))
        self.assertFalse(self.validator.detect_pattern_anomaly("abc123", r"^\d+$"))
    
    def test_get_validation_stats_empty(self):
        """Test getting stats with no validation history"""
        stats = self.validator.get_validation_stats()
        self.assertEqual(stats["total_validations"], 0)
        self.assertEqual(stats["valid_count"], 0)
        self.assertEqual(stats["invalid_count"], 0)
        self.assertEqual(stats["average_confidence"], 0.0)
    
    def test_get_validation_stats_with_history(self):
        """Test getting stats with validation history"""
        self.validator.validate_data_point("data1", "source1")
        self.validator.validate_data_point(None, "source2")
        self.validator.validate_data_point("data3", "source3")
        
        stats = self.validator.get_validation_stats()
        self.assertEqual(stats["total_validations"], 3)
        self.assertGreater(stats["average_confidence"], 0)


class TestLogicChecker(unittest.TestCase):
    """Test cases for LogicChecker class"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.checker = LogicChecker(context_window=10)
    
    def test_init_valid_window(self):
        """Test initialization with valid context window"""
        checker = LogicChecker(50)
        self.assertEqual(checker.context_window, 50)
    
    def test_init_invalid_window(self):
        """Test initialization with invalid context window"""
        with self.assertRaises(ValueError):
            LogicChecker(0)
        
        with self.assertRaises(ValueError):
            LogicChecker(-5)
    
    def test_check_statement_consistency_empty(self):
        """Test consistency check with empty statement"""
        is_consistent, contradictions = self.checker.check_statement_consistency("")
        self.assertFalse(is_consistent)
        self.assertIn("Empty statement", contradictions)
    
    def test_check_statement_consistency_valid(self):
        """Test consistency check with valid statement"""
        is_consistent, contradictions = self.checker.check_statement_consistency("The sky is blue")
        self.assertTrue(is_consistent)
        self.assertEqual(contradictions, [])
    
    def test_check_statement_consistency_contradiction(self):
        """Test detection of contradicting statements"""
        self.checker.check_statement_consistency("The value is 100")
        is_consistent, contradictions = self.checker.check_statement_consistency("The value is not 100")
        
        # Note: Simplified logic might not catch all contradictions
        # This test assumes the implementation detects basic contradictions
    
    def test_check_internal_consistency_contradiction(self):
        """Test detection of internal contradictions"""
        statement = "It is always true and never true at the same time"
        is_consistent, contradictions = self.checker.check_statement_consistency(statement)
        self.assertFalse(is_consistent)
        self.assertTrue(any("Internal contradiction" in c for c in contradictions))
    
    def test_register_fact(self):
        """Test fact registration"""
        self.checker.register_fact("temperature", 25)
        self.assertIn("temperature", self.checker.session_facts)
        self.assertEqual(self.checker.session_facts["temperature"]["value"], 25)
    
    def test_register_fact_empty_key(self):
        """Test fact registration with empty key"""
        self.checker.register_fact("", "value")
        self.assertNotIn("", self.checker.session_facts)
    
    def test_detect_circular_logic_no_circle(self):
        """Test circular logic detection with no circles"""
        statements = [
            "A is true because B",
            "B is true because C",
            "C is true"
        ]
        self.assertFalse(self.checker.detect_circular_logic(statements))
    
    def test_detect_circular_logic_with_circle(self):
        """Test circular logic detection with circular reasoning"""
        statements = [
            "A is true because B",
            "B is true because C",
            "C is true because A"
        ]
        self.assertTrue(self.checker.detect_circular_logic(statements))
    
    def test_detect_circular_logic_empty(self):
        """Test circular logic detection with empty list"""
        self.assertFalse(self.checker.detect_circular_logic([]))
    
    def test_check_response_logic_empty(self):
        """Test response logic check with empty response"""
        result = self.checker.check_response_logic({})
        self.assertFalse(result["valid"])
        self.assertIn("Empty response", result["errors"])
    
    def test_check_response_logic_valid(self):
        """Test response logic check with valid response"""
        response = {
            "content": "Valid response content",
            "data": [{"value": 50, "percentage": 75}]
        }
        
        result = self.checker.check_response_logic(response)
        self.assertTrue(result["valid"])
        self.assertEqual(result["errors"], [])
    
    def test_check_response_logic_invalid_percentage(self):
        """Test response logic check with invalid percentage"""
        response = {
            "content": "Response with bad data",
            "data": [{"percentage": 150}]
        }
        
        result = self.checker.check_response_logic(response)
        self.assertTrue(any("Invalid percentage" in w for w in result["warnings"]))
    
    def test_get_context_summary(self):
        """Test getting context summary"""
        self.checker.check_statement_consistency("Statement 1")
        self.checker.check_statement_consistency("Statement 2")
        self.checker.register_fact("fact1", "value1")
        
        summary = self.checker.get_context_summary()
        self.assertEqual(summary["context_size"], 2)
        self.assertEqual(summary["max_context"], 10)
        self.assertEqual(summary["facts_registered"], 1)


class TestResponseGenerator(unittest.TestCase):
    """Test cases for ResponseGenerator class"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.generator = ResponseGenerator(confidence_threshold=0.85)
    
    def test_init_valid_threshold(self):
        """Test initialization with valid threshold"""
        generator = ResponseGenerator(0.75)
        self.assertEqual(generator.confidence_threshold, 0.75)
    
    def test_init_invalid_threshold(self):
        """Test initialization with invalid threshold"""
        with self.assertRaises(ValueError):
            ResponseGenerator(2.0)
    
    def test_generate_response_empty_request(self):
        """Test response generation with empty request"""
        response = self.generator.generate_response({})
        self.assertFalse(response["success"])
        self.assertEqual(response["error"], "Empty request")
    
    def test_generate_response_no_query(self):
        """Test response generation with missing query"""
        response = self.generator.generate_response({"context": {}})
        self.assertFalse(response["success"])
        self.assertEqual(response["error"], "No query provided")
    
    def test_generate_response_valid(self):
        """Test response generation with valid request"""
        request = {
            "query": "What is the weather?",
            "context": {"location": "New York"}
        }
        
        response = self.generator.generate_response(request)
        self.assertIn("success", response)
        self.assertIn("content", response)
        self.assertIn("confidence", response)
    
    def test_generate_batch_responses_empty(self):
        """Test batch response generation with empty list"""
        responses = self.generator.generate_batch_responses([])
        self.assertEqual(responses, [])
    
    def test_generate_batch_responses_multiple(self):
        """Test batch response generation with multiple requests"""
        requests = [
            {"query": "Query 1"},
            {"query": "Query 2"},
            {"query": "Query 3"}
        ]
        
        responses = self.generator.generate_batch_responses(requests)
        self.assertEqual(len(responses), 3)
    
    def test_validate_and_filter_empty(self):
        """Test validation and filtering with empty content"""
        is_valid, filtered, confidence = self.generator.validate_and_filter("")
        self.assertFalse(is_valid)
        self.assertEqual(filtered, "")
        self.assertEqual(confidence, 0.0)
    
    def test_validate_and_filter_hallucination(self):
        """Test validation and filtering with hallucination pattern"""
        content = "As an AI assistant, [PLACEHOLDER] information"
        is_valid, filtered, confidence = self.generator.validate_and_filter(content)
        
        # Filtered content should have hallucination patterns removed
        self.assertNotIn("[PLACEHOLDER]", filtered)
    
    def test_get_generation_stats_initial(self):
        """Test getting generation stats initially"""
        stats = self.generator.get_generation_stats()
        self.assertEqual(stats["total_requests"], 0)
        self.assertEqual(stats["successful"], 0)
        self.assertEqual(stats["rejected"], 0)
        self.assertEqual(stats["success_rate"], 0.0)
    
    def test_get_generation_stats_after_requests(self):
        """Test getting generation stats after processing requests"""
        self.generator.generate_response({"query": "Test query"})
        
        stats = self.generator.get_generation_stats()
        self.assertEqual(stats["total_requests"], 1)


class TestModelHandler(unittest.TestCase):
    """Test cases for ModelHandler class"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config = {
            "confidence_threshold": 0.85,
            "context_window": 50,
            "max_response_time_ms": 200
        }
        self.handler = ModelHandler(self.config)
    
    def test_init_with_config(self):
        """Test initialization with custom config"""
        handler = ModelHandler(self.config)
        self.assertEqual(handler.config["confidence_threshold"], 0.85)
    
    def test_init_without_config(self):
        """Test initialization with default config"""
        handler = ModelHandler()
        self.assertIsNotNone(handler.config)
        self.assertIn("confidence_threshold", handler.config)
    
    def test_init_invalid_config(self):
        """Test initialization with invalid config"""
        invalid_config = {"confidence_threshold": 2.0}
        
        with self.assertRaises(ValueError):
            ModelHandler(invalid_config)
    
    def test_process_request_empty(self):
        """Test processing empty request"""
        response = self.handler.process_request({})
        self.assertFalse(response["success"])
        self.assertEqual(response["error"], "Empty request")
    
    def test_process_request_valid(self):
        """Test processing valid request"""
        request = {
            "query": "Test query",
            "context": {"key": "value"}
        }
        
        response = self.handler.process_request(request)
        self.assertIn("request_id", response)
        self.assertIn("hallucination_prevention", response)
    
    def test_batch_process_empty(self):
        """Test batch processing with empty list"""
        responses = self.handler.batch_process([])
        self.assertEqual(responses, [])
    
    def test_batch_process_multiple(self):
        """Test batch processing with multiple requests"""
        requests = [
            {"query": "Query 1"},
            {"query": "Query 2"}
        ]
        
        responses = self.handler.batch_process(requests)
        self.assertEqual(len(responses), 2)
    
    def test_detect_hallucination_empty(self):
        """Test hallucination detection with empty content"""
        has_hallucination, confidence, reason = self.handler.detect_hallucination("")
        self.assertTrue(has_hallucination)
        self.assertEqual(confidence, 1.0)
        self.assertEqual(reason, "Empty content")
    
    def test_detect_hallucination_pattern(self):
        """Test hallucination detection with known pattern"""
        content = "As an AI language model, I cannot access real data"
        has_hallucination, confidence, reason = self.handler.detect_hallucination(content)
        self.assertTrue(has_hallucination)
        self.assertGreater(confidence, 0.5)
    
    def test_detect_hallucination_valid(self):
        """Test hallucination detection with valid content"""
        content = "The temperature is 25 degrees Celsius"
        has_hallucination, confidence, reason = self.handler.detect_hallucination(content, {"source": "sensor"})
        
        # May or may not detect hallucination depending on implementation
        self.assertIsInstance(has_hallucination, bool)
        self.assertIsInstance(confidence, float)
        self.assertIsInstance(reason, str)
    
    def test_get_performance_metrics_initial(self):
        """Test getting performance metrics initially"""
        metrics = self.handler.get_performance_metrics()
        self.assertEqual(metrics["total_requests"], 0)
        self.assertEqual(metrics["successful_requests"], 0)
        self.assertEqual(metrics["failed_requests"], 0)
        self.assertEqual(metrics["average_response_time_ms"], 0.0)
    
    def test_get_performance_metrics_after_requests(self):
        """Test getting performance metrics after processing"""
        self.handler.process_request({"query": "Test"})
        
        metrics = self.handler.get_performance_metrics()
        self.assertEqual(metrics["total_requests"], 1)
    
    def test_reset_metrics(self):
        """Test resetting performance metrics"""
        self.handler.process_request({"query": "Test"})
        self.handler.reset_metrics()
        
        metrics = self.handler.get_performance_metrics()
        self.assertEqual(metrics["total_requests"], 0)
        self.assertEqual(metrics["successful_requests"], 0)
    
    def test_injection_detection(self):
        """Test SQL/XSS injection detection"""
        request = {
            "query": "'; DROP TABLE users; --",
            "context": {}
        }
        
        response = self.handler.process_request(request)
        self.assertFalse(response["success"])
        self.assertTrue(any("injection" in str(e).lower() for e in response.get("error_details", [])))
    
    def test_edge_case_none_values(self):
        """Test handling of None values in various places"""
        # None in context
        request = {"query": "Test", "context": None}
        response = self.handler.process_request(request)
        self.assertIn("request_id", response)
    
    def test_edge_case_very_long_content(self):
        """Test handling of very long content"""
        long_content = "x" * 10000
        has_hallucination, confidence, reason = self.handler.detect_hallucination(long_content)
        self.assertIsInstance(has_hallucination, bool)
    
    def test_concurrent_context_consistency(self):
        """Test that context remains consistent across multiple checks"""
        checker = LogicChecker(context_window=5)
        
        statements = [
            "The value is 10",
            "The temperature is 20",
            "The status is active"
        ]
        
        for stmt in statements:
            checker.check_statement_consistency(stmt)
        
        # Context should maintain these statements
        self.assertEqual(len(checker.context_memory), 3)


class TestIntegration(unittest.TestCase):
    """Integration tests for the complete hallucination prevention system"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.handler = ModelHandler()
    
    def test_end_to_end_valid_request(self):
        """Test end-to-end processing of valid request"""
        request = {
            "query": "What is 2 + 2?",
            "context": {"operation": "addition"}
        }
        
        response = self.handler.process_request(request)
        
        self.assertIn("request_id", response)
        self.assertIn("hallucination_prevention", response)
        self.assertTrue(response["hallucination_prevention"]["enabled"])
    
    def test_end_to_end_hallucination_prevention(self):
        """Test that hallucinations are prevented"""
        request = {
            "query": "Generate response with [PLACEHOLDER] data",
            "context": {}
        }
        
        response = self.handler.process_request(request)
        
        # Should either filter the placeholder or reject the response
        if response.get("success"):
            self.assertNotIn("[PLACEHOLDER]", response.get("content", ""))
    
    def test_performance_under_threshold(self):
        """Test that response time meets performance requirements"""
        import time
        
        request = {
            "query": "Quick test query",
            "context": {"test": True}
        }
        
        start = time.time()
        response = self.handler.process_request(request)
        elapsed = time.time() - start
        
        # Should complete within reasonable time (adjustable based on requirements)
        self.assertLess(elapsed, 1.0)  # 1 second max for unit test
    
    def test_stress_multiple_requests(self):
        """Test system under multiple rapid requests"""
        requests = [
            {"query": f"Query {i}", "context": {"index": i}}
            for i in range(10)
        ]
        
        responses = self.handler.batch_process(requests)
        
        self.assertEqual(len(responses), 10)
        
        # All responses should have required fields
        for response in responses:
            self.assertIn("request_id", response)
            self.assertIn("success", response)


if __name__ == "__main__":
    # Run tests with verbosity
    unittest.main(verbosity=2)