# Conditional structures

A program often makes different decisions depending on circumstances: if the mark is above 10, the student passes; otherwise, they fail. These conditional branches are the heart of algorithmic logic.

:::definition
A **condition** is a logical expression that evaluates to TRUE or FALSE. It uses comparison operators (=, ≠, <, >, ≤, ≥) and logical operators (AND, OR, NOT).

A **conditional structure** (or alternative) executes different blocks of instructions depending on whether the condition is TRUE or FALSE.
:::

## The IF…THEN…ELSE structure

:::propriete
**Full form (with ELSE):**

```
IF condition THEN
  // Block executed if condition is TRUE
  true_instructions
ELSE
  // Block executed if condition is FALSE
  false_instructions
ENDIF
```

**Reduced form (without ELSE):**

```
IF condition THEN
  // Executed only if TRUE
  instructions
ENDIF
```

If the condition is FALSE in the reduced form, execution jumps directly to ENDIF.
:::

:::exemple
**Problem**: Determine whether a number is positive, negative or zero.

```
ALGORITHM Number_Sign
VARIABLES
  n : REAL
BEGIN
  WRITE("Enter a number: ")
  READ(n)
  IF n > 0 THEN
    WRITE("The number is positive.")
  ELSE
    IF n < 0 THEN
      WRITE("The number is negative.")
    ELSE
      WRITE("The number is zero.")
    ENDIF
  ENDIF
END
```

This code uses a **nested structure**: an IF inside another IF.
:::

## The CASE structure

:::definition
The **CASE** structure allows multiple possible values of a variable to be handled without writing many nested IFs. It is more readable when testing the same variable against several values.

```
CASE variable OF
  value1: instructions_1
  value2: instructions_2
  value3, value4: instructions_3_4
  OTHERWISE: default_instructions
ENDCASE
```
:::

:::exemple
**Problem**: Display the grade based on a student's mark (out of 20).

```
ALGORITHM Grade
VARIABLES
  mark : INTEGER
BEGIN
  READ(mark)
  IF mark < 0 OR mark > 20 THEN
    WRITE("Invalid mark.")
  ELSE
    IF mark >= 16 THEN
      WRITE("Distinction")
    ELSE
      IF mark >= 14 THEN
        WRITE("Merit")
      ELSE
        IF mark >= 12 THEN
          WRITE("Credit")
        ELSE
          IF mark >= 10 THEN
            WRITE("Pass")
          ELSE
            WRITE("Fail")
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  ENDIF
END
```

**Execution trace** (mark = 15):
1. 15 < 0 OR 15 > 20 → FALSE → enter ELSE
2. 15 ≥ 16 → FALSE → enter ELSE
3. 15 ≥ 14 → TRUE → display «Merit»
:::

## Compound conditions

:::propriete
Multiple conditions can be combined with AND, OR, NOT:

| Expression | True when... |
|---|---|
| (a > 0) AND (a < 10) | a is strictly between 0 and 10 |
| (mark = 20) OR (grade = "A") | one or the other is true |
| NOT (isConnected) | the user is not connected |

**Truth table for AND:**

| A | B | A AND B |
|---|---|---|
| TRUE | TRUE | TRUE |
| TRUE | FALSE | FALSE |
| FALSE | TRUE | FALSE |
| FALSE | FALSE | FALSE |

**Truth table for OR:**

| A | B | A OR B |
|---|---|---|
| TRUE | TRUE | TRUE |
| TRUE | FALSE | TRUE |
| FALSE | TRUE | TRUE |
| FALSE | FALSE | FALSE |
:::

:::methode
To write a conditional structure:

1. **Formulate the condition** as a logical expression (True/False).
2. **Write the THEN block**: what happens if the condition is true.
3. **Write the ELSE block** (if necessary): what happens if the condition is false.
4. **Close with ENDIF**.
5. **Test** with at least two values: one that makes the condition true and one that makes it false.
:::

:::attention
Do not confuse = (comparison) and ← (assignment):
- `IF mark = 10 THEN` → tests whether mark equals 10 (COMPARISON).
- `mark ← 10` → stores the value 10 in mark (ASSIGNMENT).

In algorithmics, = is used for comparison (unlike Python which uses ==).
:::

:::retenir
- A **condition** is a TRUE/FALSE expression using operators <, >, ≤, ≥, =, ≠.
- **IF…THEN…ELSE…ENDIF**: THEN block if TRUE, ELSE block if FALSE. ELSE is optional.
- **CASE**: tests multiple values of the same variable, more readable than many nested IFs.
- **Compound conditions**: AND (both true), OR (at least one true), NOT (reverses).
- Always test the algorithm with values covering each branch of the IF.
:::
