// TypeScript file to satisfy tsconfig
export function greet(name: string): string {
  if (!name) {
    throw new Error('Name is required');
  }
  return `Hello, ${name}!`;
}

export function calculate(a: number, b: number, operation: string): number {
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