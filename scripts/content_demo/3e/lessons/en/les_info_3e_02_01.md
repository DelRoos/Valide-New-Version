# Introduction to algorithms and pseudocode

Before writing a program, every good computer scientist first thinks about the **method**: what steps must be followed to solve the problem? This is what algorithms formalise.

:::definition
An **algorithm** is a **finite**, **unambiguous** and **ordered** sequence of instructions for solving a problem or completing a task. An algorithm:

- Takes **input data** (Input).
- Performs **processing** (calculations, tests, loops).
- Produces **output results** (Output).

The word «algorithm» comes from the name of the Arab mathematician Al-Khwarizmi (9th century).
:::

## Properties of a valid algorithm

:::propriete
A valid algorithm must have these four properties:

1. **Finiteness**: it must terminate in a finite number of steps. An algorithm that loops indefinitely is not valid.
2. **Unambiguity**: each instruction must be precise and not open to interpretation.
3. **Generality**: it must work for all valid inputs, not just a particular case.
4. **Effectiveness**: each instruction must be executable by the machine (or a person).
:::

## Pseudocode

:::definition
**Pseudocode** (or algorithmic language) is an intermediate notation between natural language and a programming language. It allows an algorithm to be written in a readable and precise way, without worrying about the exact syntax of a particular language (Python, C, Java…).

The general structure is as follows:
:::

:::propriete
General structure of an algorithm in pseudocode:

```
ALGORITHM AlgorithmName
CONSTANTS
  CONSTANT_NAME = value
VARIABLES
  name1, name2 : TYPE
  name3 : TYPE
BEGIN
  // Instructions
  READ(variable)
  variable ← expression
  WRITE(variable or text)
END
```

Keywords in CAPITALS (ALGORITHM, VARIABLES, BEGIN, END, READ, WRITE) are part of the mandatory structure.
:::

## Basic instructions

:::propriete
| Instruction | Role | Example |
|---|---|---|
| `READ(x)` | Take a value from the user and store it in x | READ(age) |
| `WRITE(x)` | Display the value of x on screen | WRITE(age) |
| `WRITE("text")` | Display fixed text | WRITE("Hello!") |
| `x ← expression` | Assign the result of the expression to x | sum ← a + b |
:::

## First complete example

:::exemple
**Problem**: calculate the perimeter of a rectangle with length L and width w.

**Analysis**:
- Input: length L, width w.
- Processing: perimeter = 2 × (L + w).
- Output: display the perimeter.

**Algorithm in pseudocode**:

```
ALGORITHM Rectangle_Perimeter
VARIABLES
  L, w, P : REAL
BEGIN
  WRITE("Enter the length: ")
  READ(L)
  WRITE("Enter the width: ")
  READ(w)
  P ← 2 * (L + w)
  WRITE("The perimeter is: ")
  WRITE(P)
END
```

**Test**: if the user enters L = 5 and w = 3, then P = 2 × (5 + 3) = 2 × 8 = 16.
:::

## The flowchart

:::definition
A **flowchart** is a graphical representation of an algorithm. The symbols used are:

| Symbol | Shape | Meaning |
|---|---|---|
| Start/End | Oval | Starting or ending point |
| Input/Output | Parallelogram | READ or WRITE |
| Processing | Rectangle | Assignment, calculation |
| Decision | Diamond | Test (IF…) |
| Connector | Circle | Reference to another part |
:::

:::methode
To design an algorithm, follow these steps:

1. **Understand the problem**: read the statement carefully.
2. **Identify the inputs**: what data does the user provide?
3. **Identify the output**: what result must be produced?
4. **Describe the processing**: what operations are performed between inputs and output?
5. **Write the pseudocode**: translate the processing into instructions.
6. **Test the algorithm**: verify with example values.
:::

:::attention
An algorithm is written **before** the computer code, not after. Neglecting this step often leads to writing an incorrect program that must be completely rewritten. The algorithm is the construction plan; the code is the construction itself.
:::

:::retenir
- An **algorithm** is a finite, unambiguous and ordered sequence of instructions for solving a problem.
- Properties: **finiteness**, **unambiguity**, **generality**, **effectiveness**.
- **Pseudocode** is the textual notation of an algorithm, independent of any programming language.
- Basic instructions: **READ** (input), **WRITE** (output), **←** (assignment).
- Structure: ALGORITHM → VARIABLES → BEGIN … END.
:::
