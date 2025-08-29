"""
Logic Checker Module for AMB Hallucination Prevention
Ensures logical consistency in generated responses
"""

import logging
from typing import List, Dict, Any, Tuple, Optional
from collections import deque
from datetime import datetime

logger = logging.getLogger(__name__)


class LogicChecker:
    """
    Checks for logical contradictions and inconsistencies in AMB responses
    """
    
    def __init__(self, context_window: int = 100):
        """
        Initialize LogicChecker
        
        Args:
            context_window: Number of previous statements to maintain for consistency checking
        """
        if context_window <= 0:
            raise ValueError("Context window must be positive")
        
        self.context_window = context_window
        self.context_memory = deque(maxlen=context_window)
        self.contradiction_rules = self._initialize_rules()
        self.session_facts = {}
        logger.info(f"LogicChecker initialized with context window: {context_window}")
    
    def check_statement_consistency(self, statement: str, metadata: Dict[str, Any] = None) -> Tuple[bool, List[str]]:
        """
        Check if statement is logically consistent with context
        
        Args:
            statement: Statement to check
            metadata: Optional metadata about the statement
            
        Returns:
            Tuple of (is_consistent, list_of_contradictions)
        """
        try:
            if not statement:
                logger.warning("Empty statement provided")
                return False, ["Empty statement"]
            
            contradictions = []
            
            # Check against context memory
            context_contradictions = self._check_context_consistency(statement)
            contradictions.extend(context_contradictions)
            
            # Check against session facts
            fact_contradictions = self._check_fact_consistency(statement)
            contradictions.extend(fact_contradictions)
            
            # Check internal statement consistency
            internal_contradictions = self._check_internal_consistency(statement)
            contradictions.extend(internal_contradictions)
            
            is_consistent = len(contradictions) == 0
            
            # Add to context if consistent
            if is_consistent:
                self._add_to_context(statement, metadata)
            
            if contradictions:
                logger.warning(f"Logic inconsistencies found: {contradictions}")
            else:
                logger.debug("Statement is logically consistent")
            
            return is_consistent, contradictions
            
        except Exception as e:
            logger.error(f"Logic check error: {str(e)}")
            return False, [f"Logic check error: {str(e)}"]
    
    def check_response_logic(self, response: Dict[str, Any]) -> Dict[str, Any]:
        """
        Comprehensive logic check for entire response
        
        Args:
            response: Response dictionary to check
            
        Returns:
            Dictionary with logic check results
        """
        if not response:
            return {
                "valid": False,
                "errors": ["Empty response"],
                "warnings": [],
                "consistency_score": 0.0
            }
        
        errors = []
        warnings = []
        consistency_checks = []
        
        # Check main content
        content = response.get("content", "")
        if content:
            is_consistent, contradictions = self.check_statement_consistency(content)
            consistency_checks.append(is_consistent)
            
            if not is_consistent:
                errors.extend(contradictions)
        
        # Check supporting data
        data_points = response.get("data", [])
        for point in data_points:
            is_consistent, issues = self._validate_data_logic(point)
            consistency_checks.append(is_consistent)
            
            if not is_consistent:
                warnings.extend(issues)
        
        # Calculate overall consistency score
        consistency_score = sum(consistency_checks) / len(consistency_checks) if consistency_checks else 0.0
        
        result = {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
            "consistency_score": consistency_score
        }
        
        logger.info(f"Response logic check complete: valid={result['valid']}, score={consistency_score:.2f}")
        
        return result
    
    def register_fact(self, fact_key: str, fact_value: Any):
        """
        Register a fact for consistency checking
        
        Args:
            fact_key: Identifier for the fact
            fact_value: Value of the fact
        """
        if not fact_key:
            logger.warning("Cannot register fact with empty key")
            return
        
        self.session_facts[fact_key] = {
            "value": fact_value,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        logger.debug(f"Fact registered: {fact_key} = {fact_value}")
    
    def detect_circular_logic(self, statements: List[str]) -> bool:
        """
        Detect circular reasoning in statements
        
        Args:
            statements: List of statements to check
            
        Returns:
            True if circular logic detected, False otherwise
        """
        if not statements or len(statements) < 2:
            return False
        
        # Build dependency graph
        dependencies = {}
        
        for i, stmt in enumerate(statements):
            # Extract logical connections (simplified)
            if "because" in stmt.lower():
                parts = stmt.lower().split("because")
                if len(parts) == 2:
                    conclusion = parts[0].strip()
                    premise = parts[1].strip()
                    
                    if conclusion not in dependencies:
                        dependencies[conclusion] = []
                    dependencies[conclusion].append(premise)
        
        # Check for cycles
        def has_cycle(node, visited, rec_stack):
            visited.add(node)
            rec_stack.add(node)
            
            for neighbor in dependencies.get(node, []):
                if neighbor not in visited:
                    if has_cycle(neighbor, visited, rec_stack):
                        return True
                elif neighbor in rec_stack:
                    return True
            
            rec_stack.remove(node)
            return False
        
        visited = set()
        
        for node in dependencies:
            if node not in visited:
                if has_cycle(node, visited, set()):
                    logger.warning("Circular logic detected in statements")
                    return True
        
        return False
    
    def _check_context_consistency(self, statement: str) -> List[str]:
        """
        Check statement against context memory
        
        Args:
            statement: Statement to check
            
        Returns:
            List of contradictions found
        """
        contradictions = []
        
        for context_item in self.context_memory:
            # Check for direct contradictions
            if self._statements_contradict(statement, context_item["statement"]):
                contradictions.append(f"Contradicts previous: {context_item['statement'][:50]}...")
        
        return contradictions
    
    def _check_fact_consistency(self, statement: str) -> List[str]:
        """
        Check statement against registered facts
        
        Args:
            statement: Statement to check
            
        Returns:
            List of contradictions found
        """
        contradictions = []
        statement_lower = statement.lower()
        
        for fact_key, fact_data in self.session_facts.items():
            fact_value = str(fact_data["value"]).lower()
            
            # Simple contradiction detection
            if fact_key.lower() in statement_lower:
                # Check if statement contradicts the fact
                negations = ["not", "isn't", "aren't", "wasn't", "weren't", "never", "no"]
                
                for neg in negations:
                    if neg in statement_lower and fact_value in statement_lower:
                        contradictions.append(f"Contradicts fact: {fact_key} = {fact_data['value']}")
                        break
        
        return contradictions
    
    def _check_internal_consistency(self, statement: str) -> List[str]:
        """
        Check for internal contradictions within a statement
        
        Args:
            statement: Statement to check
            
        Returns:
            List of internal contradictions
        """
        contradictions = []
        
        # Check for self-contradicting phrases
        contradictory_patterns = [
            ("always", "never"),
            ("all", "none"),
            ("everyone", "no one"),
            ("true", "false"),
            ("yes", "no")
        ]
        
        statement_lower = statement.lower()
        
        for pattern1, pattern2 in contradictory_patterns:
            if pattern1 in statement_lower and pattern2 in statement_lower:
                contradictions.append(f"Internal contradiction: contains both '{pattern1}' and '{pattern2}'")
        
        return contradictions
    
    def _statements_contradict(self, stmt1: str, stmt2: str) -> bool:
        """
        Check if two statements contradict each other
        
        Args:
            stmt1: First statement
            stmt2: Second statement
            
        Returns:
            True if statements contradict, False otherwise
        """
        # Simplified contradiction detection
        stmt1_lower = stmt1.lower()
        stmt2_lower = stmt2.lower()
        
        # Check for opposite assertions
        if ("is" in stmt1_lower and "is not" in stmt2_lower) or \
           ("is not" in stmt1_lower and "is" in stmt2_lower):
            # Check if they're about the same subject
            words1 = set(stmt1_lower.split())
            words2 = set(stmt2_lower.split())
            common_words = words1.intersection(words2)
            
            if len(common_words) > 3:  # Arbitrary threshold
                return True
        
        return False
    
    def _validate_data_logic(self, data_point: Any) -> Tuple[bool, List[str]]:
        """
        Validate logical consistency of data point
        
        Args:
            data_point: Data point to validate
            
        Returns:
            Tuple of (is_valid, issues)
        """
        issues = []
        
        if data_point is None:
            issues.append("Null data point")
            return False, issues
        
        # Check for logical impossibilities in numeric data
        if isinstance(data_point, dict):
            if "percentage" in data_point:
                value = data_point.get("percentage")
                if value is not None and (value < 0 or value > 100):
                    issues.append(f"Invalid percentage: {value}")
            
            if "count" in data_point:
                value = data_point.get("count")
                if value is not None and value < 0:
                    issues.append(f"Negative count: {value}")
        
        return len(issues) == 0, issues
    
    def _add_to_context(self, statement: str, metadata: Dict[str, Any] = None):
        """
        Add statement to context memory
        
        Args:
            statement: Statement to add
            metadata: Optional metadata
        """
        context_item = {
            "statement": statement,
            "timestamp": datetime.utcnow().isoformat(),
            "metadata": metadata or {}
        }
        
        self.context_memory.append(context_item)
    
    def _initialize_rules(self) -> List[Dict[str, Any]]:
        """
        Initialize contradiction detection rules
        
        Returns:
            List of rule dictionaries
        """
        return [
            {
                "name": "temporal_consistency",
                "description": "Events must follow temporal logic"
            },
            {
                "name": "numerical_consistency",
                "description": "Numbers must be mathematically consistent"
            },
            {
                "name": "categorical_consistency",
                "description": "Categories must be mutually exclusive when appropriate"
            }
        ]
    
    def get_context_summary(self) -> Dict[str, Any]:
        """
        Get summary of current context
        
        Returns:
            Dictionary with context summary
        """
        return {
            "context_size": len(self.context_memory),
            "max_context": self.context_window,
            "facts_registered": len(self.session_facts),
            "oldest_context": self.context_memory[0]["timestamp"] if self.context_memory else None,
            "newest_context": self.context_memory[-1]["timestamp"] if self.context_memory else None
        }