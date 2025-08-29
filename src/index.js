// Demo source file for lifecycle workflow
function greet(name) {
  if (!name) {
    throw new Error('Name is required');
  }
  return `Hello, ${name}!`;
}

function calculate(a, b, operation) {
  switch(operation) {
  case 'add':
    return a + b;
  case 'subtract':
    return a - b;
  case 'multiply':
    return a * b;
  case 'divide':
    if (b === 0) throw new Error('Division by zero');
    return a / b;
  default:
    throw new Error('Invalid operation');
  }
}

module.exports = { greet, calculate };