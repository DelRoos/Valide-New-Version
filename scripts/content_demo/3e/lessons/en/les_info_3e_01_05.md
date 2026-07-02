# Databases: organising information

A hospital manages thousands of patient records, a school hundreds of students, a library thousands of books. Without databases, managing such quantities of information would be impossible. Databases are at the heart of modern computing systems.

:::definition
A **database** is an organised collection of structured information, stored in a way that facilitates access, management and updating. It is managed by a **Database Management System** (DBMS).
:::

## Structure of a database

:::definition
A relational database is organised into **tables** (or relations). Each table is made up of:

- **Fields** (or attributes): columns defining the type of information stored.
- **Records** (or tuples): rows representing each object or person.
- **Primary key**: a unique field that unambiguously identifies each record (e.g. ID number, StudentNumber).
:::

:::exemple
STUDENTS table in a school database:

| ID | Surname | First name | DateOfBirth | Class |
|---|---|---|---|---|
| E001 | MVOGO | Amara | 12/03/2011 | Y10A |
| E002 | BELLO | Fadimatou | 25/07/2010 | Y10A |
| E003 | NGUYEN | Paul | 08/11/2011 | Y10B |

- **Fields**: ID, Surname, FirstName, DateOfBirth, Class.
- **Records**: each row (E001 Mvogo, E002 Bello, E003 Nguyen).
- **Primary key**: ID (unique for each student).
:::

## The DBMS (Database Management System)

:::definition
A **DBMS** is the software that allows a database to be created, organised, queried and maintained. It ensures:

- **Data entry** and modification.
- **Searching** and information extraction through **queries**.
- Data **security** and confidentiality.
- Data **consistency** (no duplicates, constraints respected).

DBMS examples: **MySQL** (open source, very widespread on the Internet), **PostgreSQL** (open source), **Microsoft Access** (paid, desktop), **LibreOffice Base** (free).
:::

## Queries

:::definition
A **query** is a question put to the database to extract specific information. In SQL (Structured Query Language), the basic query is:

```
SELECT field1, field2
FROM TableName
WHERE condition;
```
:::

:::exemple
To find all students in class Y10A:

```sql
SELECT Surname, FirstName
FROM STUDENTS
WHERE Class = 'Y10A';
```

Result:
| Surname | FirstName |
|---|---|
| MVOGO | Amara |
| BELLO | Fadimatou |

The DBMS filters and returns only the records matching the condition.
:::

## Advantages of databases

:::propriete
Compared to a paper file or a simple spreadsheet, a database offers:

| Advantage | Description |
|---|---|
| **Capacity** | Handles millions of records |
| **Speed** | Instant search even in large volumes |
| **Integrity** | Avoids duplicates and inconsistencies through constraints |
| **Security** | User access rights management |
| **Sharing** | Multiple simultaneous users |
| **Consistency** | Centralised updating: only one place to modify |
:::

## Applications in Cameroon

:::exemple
In Cameroon, databases are used in many areas:

- **MINESEC**: student registers, BEPC and BAC results.
- **Hospitals**: patient medical records.
- **MTN / Orange**: Mobile Money subscriber management.
- **Town halls**: civil registry (births, marriages, deaths).
- **National libraries**: book and archive catalogues.
:::

:::methode
To design a database table:

1. **Identify the object** to be described (student, book, patient, product…).
2. **List the necessary information** (surname, first name, date, quantity…).
3. **Define the type** of each field (text, number, date, boolean…).
4. **Choose the primary key**: a unique, immutable field (ID number, ISBN, national ID…).
5. **Avoid redundancy**: store each piece of information only once.
:::

:::retenir
- A **database** is an organised collection of information managed by a **DBMS**.
- Structure: **tables** → **fields** (columns) + **records** (rows) + **primary key** (unique identifier).
- A **DBMS** (MySQL, LibreOffice Base, Access) enables creating, modifying, querying and securing data.
- **Queries** (in SQL) allow information to be extracted according to specific criteria.
- Applications: school registers (BEPC), medical records, Mobile Money management in Cameroon.
:::
