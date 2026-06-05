## Welcome

A reference integral:

$$\int_0^1 x^2 \, dx = \frac{1}{3}$$

App boot flow:

```mermaid
flowchart LR
    A([Boot]) --> B[Firebase init]
    B --> C[Anonymous sign-in]
    C --> D[Smoke Firestore]
    D --> E([App ready])
```
