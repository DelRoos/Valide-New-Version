# Repetitive structures: loops

Repeating the same action ten times, a hundred times, or until a condition is met: that is the role of loops. Without them, you would have to write the same instruction a hundred times — loops make algorithms powerful and concise.

:::definition
A **loop** (or repetitive structure, or iteration) is an instruction that repeats a block of instructions multiple times. The repeated block is called the **loop body**. Each execution of the body is called an **iteration**.

There are three types of loops in algorithmics:
1. **FOR**: fixed, known number of repetitions.
2. **WHILE**: conditional repetition, condition tested **before** each iteration.
3. **REPEAT…UNTIL**: conditional repetition, condition tested **after** each iteration.
:::

## The FOR loop

:::definition
The **FOR** loop is used when the **number of iterations is known in advance**. A counter successively takes all values within a range.

```
FOR counter FROM start_value TO end_value [STEP step] DO
  // Loop body
  instructions
ENDFOR
```

- `counter` is automatically incremented by 1 (or by `step` if specified) at each iteration.
- The loop stops when `counter > end_value`.
:::

:::exemple
Display the multiplication table for 7:

```
ALGORITHM Table_7
VARIABLES
  i : INTEGER
BEGIN
  FOR i FROM 1 TO 10 DO
    WRITE(7, " × ", i, " = ", 7 * i)
  ENDFOR
END
```

Result:
```
7 × 1 = 7
7 × 2 = 14
...
7 × 10 = 70
```

The loop executes 10 times (i = 1, 2, 3, …, 10).
:::

## The WHILE loop

:::definition
The **WHILE** loop is used when the number of iterations is not known in advance. The condition is tested **before** each iteration. If it is FALSE from the start, the body is never executed.

```
WHILE condition DO
  // Loop body
  instructions
ENDWHILE
```

The loop continues while the condition is TRUE. It stops as soon as the condition becomes FALSE.
:::

:::exemple
Calculate the sum of positive integers until the sum exceeds 100:

```
ALGORITHM Sum_Limit
VARIABLES
  sum, n : INTEGER
BEGIN
  sum ← 0
  n ← 1
  WHILE sum <= 100 DO
    sum ← sum + n
    n ← n + 1
  ENDWHILE
  WRITE("The sum exceeds 100 for n = ", n - 1)
  WRITE("The sum obtained is: ", sum)
END
```
:::

## The REPEAT…UNTIL loop

:::definition
The **REPEAT…UNTIL** loop is similar to WHILE, but the condition is tested **after** each iteration. The body is therefore always executed **at least once**.

```
REPEAT
  // Loop body
  instructions
UNTIL condition
```

The loop continues while the condition is FALSE. It stops as soon as the condition becomes TRUE.
:::

:::exemple
Ask the user to enter a valid mark (between 0 and 20):

```
ALGORITHM Mark_Entry
VARIABLES
  mark : INTEGER
BEGIN
  REPEAT
    WRITE("Enter a mark between 0 and 20: ")
    READ(mark)
    IF mark < 0 OR mark > 20 THEN
      WRITE("Invalid mark, please try again.")
    ENDIF
  UNTIL (mark >= 0) AND (mark <= 20)
  WRITE("Valid mark entered: ", mark)
END
```

The block repeats until the user enters a valid mark.
:::

## Comparison of the three loops

:::propriete
| Criterion | FOR | WHILE | REPEAT…UNTIL |
|---|---|---|---|
| Number of iterations | Known in advance | Unknown | Unknown |
| Condition tested | — | Before body | After body |
| Minimum execution | 0 if start > end | 0 if condition false from start | **Always 1** |
| Typical use | Tables, counting, lists | Processing until condition | Input with validation |
:::

:::methode
To choose the right loop:

- **Number of iterations known?** → use **FOR**.
- **Number unknown, body may not execute?** → use **WHILE**.
- **Body must execute at least once (e.g. user input)?** → use **REPEAT…UNTIL**.
:::

:::attention
An **infinite loop** occurs when the WHILE condition always remains TRUE, or the UNTIL condition of a REPEAT always remains FALSE. The program runs indefinitely. Always check that the exit condition can be reached.

Example of an infinite loop:
```
i ← 1
WHILE i > 0 DO
  i ← i + 1   // i always increases → condition always true → infinite loop!
ENDWHILE
```
:::

:::retenir
- **FOR**: known number of iterations. Syntax: FOR i FROM a TO b DO … ENDFOR.
- **WHILE**: condition tested BEFORE. May never execute. Syntax: WHILE cond DO … ENDWHILE.
- **REPEAT…UNTIL**: condition tested AFTER. Always executes at least 1 time.
- An **infinite loop** is an error: check that the exit condition is reachable.
- Choose the loop based on whether the number of iterations is known (FOR) or not (WHILE / REPEAT).
:::
