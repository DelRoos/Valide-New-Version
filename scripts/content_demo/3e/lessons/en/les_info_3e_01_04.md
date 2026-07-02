# Spreadsheets and automated calculations

A spreadsheet turns a computer into a powerful calculator, able to process hundreds of pieces of data in seconds. It is an indispensable tool in accounting, statistics, science and everyday life.

:::definition
A **spreadsheet** is software that organises data into **calculation sheets** made up of **cells**, each identified by a **column** (letter) and a **row** (number). The most widely used spreadsheets are **LibreOffice Calc** (free), **Microsoft Excel** (paid) and **Google Sheets** (online).
:::

## Structure of a spreadsheet

:::propriete
A spreadsheet is organised as follows:

- **Columns**: identified by letters (A, B, C, …, Z, AA, AB…).
- **Rows**: identified by numbers (1, 2, 3, …).
- **Cell**: intersection of a column and a row, identified by its **reference** (e.g. C3 = column C, row 3).
- **Cell range**: group of contiguous cells, written with a colon (A1:A10 = from A1 to A10).

Example:

| | A | B | C |
|---|---|---|---|
| **1** | Student | Mark 1 | Mark 2 |
| **2** | Amara | 14 | 16 |
| **3** | Boukar | 12 | 18 |
:::

## Types of data in a cell

:::propriete
A cell can contain:

| Type | Example | Default alignment |
|---|---|---|
| **Text** | «Name», «Student» | Left |
| **Number** | 14, 3.5, −2 | Right |
| **Date** | 30/06/2026 | Right |
| **Formula** | =B2+C2 | Right (displays the result) |

A formula always starts with the **=** sign.
:::

## Essential formulas and functions

:::definition
A **formula** is an expression starting with **=** that performs automatic calculations. It can use:

- Arithmetic operators: **+**, **−**, **\***, **/**
- Cell references: A1, B3, C5:C10
- Predefined **functions**: SUM, AVERAGE, MAX, MIN, IF…
:::

:::propriete
Most commonly used functions in Year 10:

| Function | Syntax | Description |
|---|---|---|
| Sum | =SUM(A1:A10) | Adds values from A1 to A10 |
| Average | =AVERAGE(B1:B10) | Calculates the average of B1 to B10 |
| Maximum | =MAX(C1:C10) | Finds the largest value |
| Minimum | =MIN(C1:C10) | Finds the smallest value |
| Count | =COUNT(A1:A10) | Counts cells containing a number |
| Condition | =IF(B2>=10,"Pass","Fail") | Returns «Pass» if B2 ≥ 10, otherwise «Fail» |
:::

:::exemple
Calculating a student's weighted average:

| | A | B | C | D |
|---|---|---|---|---|
| **1** | Subject | Mark | Coeff | Mark × Coeff |
| **2** | Maths | 14 | 4 | =B2*C2 |
| **3** | French | 12 | 3 | =B3*C3 |
| **4** | Biology | 16 | 2 | =B4*C4 |
| **5** | **Total** | | =SUM(C2:C4) | =SUM(D2:D4) |
| **6** | **Average** | | | =D5/C5 |

The formula =D5/C5 calculates the weighted average: sum of (marks × coefficients) divided by the sum of coefficients.
:::

## Relative and absolute references

:::definition
When a formula is **copied**, cell references change automatically. We distinguish:

- **Relative reference** (e.g. A1): adjusts when copied (A1 becomes B1 if copied to the right).
- **Absolute reference** (e.g. $A$1): does not change when copied. The **$** symbol fixes the column, row, or both.
- **Mixed reference**: $A1 (fixed column) or A$1 (fixed row).
:::

:::exemple
If cell E2 contains =D2/$D$5 and is copied to E3:
- D2 becomes D3 (relative reference → adapts to the row).
- $D$5 remains $D$5 (absolute reference → does not change).

This allows dividing each mark by the total (in D5) without changing the reference to the total.
:::

## Charts

:::methode
To create a chart from a table:

1. **Select** the data (cells with headings and values).
2. **Insert** → **Chart** (or chart icon in the toolbar).
3. **Choose the type**: bar chart (comparison), line chart (trend), pie chart (proportions).
4. **Customise**: title, legend, colours.
5. **Confirm**: the chart is inserted into the sheet.
:::

:::attention
Do not use a pie chart if the sum of the data does not represent 100% of a whole. For example, marks out of 20 in several subjects are not suited to a pie chart — use a bar chart instead.
:::

:::retenir
- A **spreadsheet** organises data in cells identified by column (letter) and row (number), e.g. B3.
- A **formula** starts with **=** and performs automatic calculations.
- Key functions: **=SUM()**, **=AVERAGE()**, **=MAX()**, **=MIN()**, **=IF()**.
- **Absolute reference** ($A$1): does not change when copied. **Relative reference** (A1): adjusts.
- **Charts** (bar, line, pie) can be created from table data.
:::
