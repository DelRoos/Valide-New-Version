# Variables, data types and operations

Every algorithm manipulates information: numbers, text, logical values. This information is stored in **variables**, each with a **type** that defines what it can contain.

:::definition
A **variable** is a named memory space in which a value is stored. This value can be read and modified during the execution of the algorithm. A variable is characterised by:

- A **name** (identifier): e.g. age, mark, studentName.
- A **type**: the nature of the values it can store.
- A **value**: the current content of the memory space.

In pseudocode, variables are declared in the VARIABLES section before BEGIN.
:::

## Data types

:::definition
The **type** of a variable determines the nature of the values it can store and the operations that can be performed on it.

| Type | Description | Example values |
|---|---|---|
| **INTEGER** | Whole number (no decimal point) | −10, 0, 5, 1000 |
| **REAL** | Decimal number | 3.14, −2.5, 0.001 |
| **STRING** | Text (character string) | "Hello", "Amara", "Y10A" |
| **BOOLEAN** | Logical value | TRUE, FALSE |
| **CHARACTER** | A single character | 'A', 'z', '5', '?' |
:::

## Variable declaration in pseudocode

:::propriete
Variables are declared in the VARIABLES section with the syntax:

```
VARIABLES
  variableName : TYPE
  name1, name2 : TYPE   (multiple variables of the same type)
```

Examples:

```
VARIABLES
  age : INTEGER
  mark, average : REAL
  studentName : STRING
  isAdult : BOOLEAN
```
:::

## Assignment

:::definition
**Assignment** stores a value in a variable. In pseudocode, it is written with the arrow **←**:

```
variable ← expression
```

The expression to the right of **←** is **calculated first**, then the result is stored in the variable on the left.

Example:
```
a ← 5        // a equals 5
b ← 3        // b equals 3
c ← a + b    // c equals 8 (5 + 3)
a ← a + 1   // a now equals 6 (old value + 1)
```
:::

:::attention
The assignment `a ← a + 1` is valid in algorithmics (and programming): the old value of `a` (5) is read, 1 is added (result: 6), then this result is stored in `a`. After the assignment, `a` equals 6.

In mathematics, the equation a = a + 1 is impossible. In algorithmics, it is a common operation (incrementing a counter).
:::

## Operators

:::propriete
**Arithmetic operators:**

| Operator | Meaning | Example | Result |
|---|---|---|---|
| + | Addition | 7 + 3 | 10 |
| − | Subtraction | 7 − 3 | 4 |
| * | Multiplication | 7 * 3 | 21 |
| / | Real division | 7 / 2 | 3.5 |
| DIV | Integer division | 7 DIV 2 | 3 |
| MOD | Division remainder | 7 MOD 2 | 1 |

**Comparison operators:**

| Operator | Meaning |
|---|---|
| = | Equal to |
| ≠ | Not equal to |
| < | Less than |
| > | Greater than |
| ≤ | Less than or equal to |
| ≥ | Greater than or equal to |

**Logical operators:**

| Operator | Meaning | Example |
|---|---|---|
| AND | Both conditions true | (a > 0) AND (a < 10) |
| OR | At least one condition true | (mark = 20) OR (grade = "A") |
| NOT | Reverses the condition | NOT (isConnected) |
:::

## Complete example

:::exemple
**Problem**: ask the user their age and display whether they are an adult or not.

```
ALGORITHM Adulthood
VARIABLES
  age : INTEGER
BEGIN
  WRITE("What is your age? ")
  READ(age)
  IF age >= 18 THEN
    WRITE("You are an adult.")
  ELSE
    WRITE("You are a minor.")
  ENDIF
END
```

**Test 1**: age = 20 → age ≥ 18 is TRUE → displays «You are an adult.»
**Test 2**: age = 15 → age ≥ 18 is FALSE → displays «You are a minor.»
:::

:::methode
Rules for naming variables:

1. The name starts with a **letter** (not a digit).
2. The name contains only **letters, digits and underscores** (no spaces, accents or hyphens).
3. The name is **descriptive** and meaningful: `mathsMark` rather than `m`.
4. Respect **case**: `age` and `Age` are two different variables.
:::

:::retenir
- A **variable** is a named memory space for storing a modifiable value.
- Types: **INTEGER** (whole), **REAL** (decimal), **STRING** (text), **BOOLEAN** (TRUE/FALSE).
- **Assignment**: `variable ← expression` (calculate first, then store).
- **Arithmetic operators**: +, −, *, /, DIV (integer division), MOD (remainder).
- **Logical operators**: AND, OR, NOT — allow conditions to be combined.
:::
