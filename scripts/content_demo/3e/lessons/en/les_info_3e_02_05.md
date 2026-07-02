# Subprograms: functions and procedures

When the same calculation must be repeated in several places in a program, rewriting it each time is tedious and error-prone. **Subprograms** (functions and procedures) allow code to be written once and reused as many times as needed.

:::definition
A **subprogram** is a named, independent block of instructions that can be **called** (invoked) from the main program or from other subprograms. We distinguish:

- **Procedure**: performs actions (displays, variable modifications) without returning a value.
- **Function**: performs calculations and **returns a value** to the calling program.
:::

## The procedure

:::definition
A **procedure** is a subprogram that executes actions without returning a result.

**Declaration:**
```
PROCEDURE ProcedureName(param1 : TYPE1, param2 : TYPE2)
VARIABLES
  local_variables : TYPE
BEGIN
  // Procedure body
  instructions
END
```

**Call:**
```
ProcedureName(value1, value2)
```
:::

:::exemple
Procedure displaying a welcome message:

```
PROCEDURE Welcome(firstName : STRING)
BEGIN
  WRITE("Hello, ", firstName, "!")
  WRITE("Welcome to the program.")
END

// Main program
ALGORITHM Main_Program
VARIABLES
  name : STRING
BEGIN
  READ(name)
  Welcome(name)    // Procedure call
END
```

If the user enters «Amara», the procedure displays:
```
Hello, Amara!
Welcome to the program.
```
:::

## The function

:::definition
A **function** is a subprogram that performs a calculation and **returns a value** using the `RETURN` instruction.

**Declaration:**
```
FUNCTION FunctionName(param1 : TYPE1, param2 : TYPE2) : RETURN_TYPE
VARIABLES
  local_variables : TYPE
BEGIN
  // Function body
  instructions
  RETURN value
END
```

**Call:**
```
result ← FunctionName(value1, value2)
```
The returned value is stored in `result`.
:::

:::exemple
Function calculating the area of a rectangle:

```
FUNCTION Rectangle_Area(length, width : REAL) : REAL
BEGIN
  RETURN length * width
END

// Main program
ALGORITHM Area_Calculation
VARIABLES
  L, w, area : REAL
BEGIN
  WRITE("Length: ")
  READ(L)
  WRITE("Width: ")
  READ(w)
  area ← Rectangle_Area(L, w)   // Function call
  WRITE("Area = ", area)
END
```

If L = 5 and w = 3, then `Rectangle_Area(5, 3)` returns 15, and «Area = 15» is displayed.
:::

## Parameters and local variables

:::propriete
- **Parameters**: values passed to a subprogram when it is called. They are declared in parentheses in the subprogram header.
- **Local variables**: variables declared inside a subprogram. They only exist during the subprogram's execution and are inaccessible from outside.
- **Global variables**: variables declared in the main program, accessible everywhere. Use with caution.

| Characteristic | Local variable | Global variable |
|---|---|---|
| Declared in | The subprogram | The main program |
| Lifetime | Duration of the subprogram's execution | Entire program execution |
| Accessibility | Only within the subprogram | Everywhere |
:::

## Advantages of subprograms

:::propriete
| Advantage | Description |
|---|---|
| **Reusability** | Write once, call multiple times |
| **Modularity** | Divide a complex problem into sub-problems |
| **Readability** | A well-structured program is easier to understand |
| **Maintainability** | Fixing a bug in the function fixes it everywhere |
| **Testability** | Test each subprogram independently |
:::

:::methode
To design a subprogram:

1. **Identify** the repeated task or calculation to isolate.
2. **Choose**: does it return a value? → Function; otherwise → Procedure.
3. **Define the parameters**: what information does the task need?
4. **Write the body**: implement the task.
5. **Call** the subprogram from the main program.
:::

:::retenir
- A **subprogram** is a named, reusable block of instructions.
- **Procedure**: performs actions, does not return a value.
- **Function**: performs a calculation, **returns a value** using `RETURN`.
- **Parameters**: values passed at call time to customise behaviour.
- **Local variables**: only exist during the subprogram's execution.
- Advantages: reusability, modularity, readability, maintainability.
:::
