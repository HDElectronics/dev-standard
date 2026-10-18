---
id: EMB
title: Embedded C
version: 0.1.0
applies_to: pack
based_on:
  - name: BARR-C:2018 Embedded C Coding Standard
  - name: MISRA C:2023 (subset)
---

# Embedded C (EMB)

An opt-in pack for firmware written in C. It takes a practical subset of BARR-C:2018 and MISRA C:2023: the rules that prevent the most common firmware bugs and that tools can check. Projects that need full MISRA compliance (safety certification) adopt the full standard with a qualified checker and record that in an ADR. Naming follows NAM's C column, which matches BARR-C.

## Rules

### EMB-001 · MUST · Use fixed-width integer types

Use `<stdint.h>` types (`uint8_t`, `int32_t`) wherever the size matters, and `bool` from `<stdbool.h>`. Plain `int`, `long` and `char` for arithmetic are not used in driver or protocol code.

- **Why:** The size of `int` differs between an 8-bit and a 32-bit MCU. Fixed-width types make register and protocol code portable and explicit (MISRA C Directive 4.6, BARR-C).
- **Check:** `clang-tidy` with a project check or cppcheck MISRA addon for Directive 4.6.

### EMB-002 · MUST NOT · Allocate heap memory after initialization

Do not call `malloc`, `calloc`, `realloc` or `free` after system initialization. Prefer static allocation everywhere; use fixed-size pools where a dynamic count is unavoidable.

- **Why:** Heap fragmentation and allocation failure in a long-running device cause faults that appear after days or weeks (MISRA C Rule 21.3).
- **Check:** Linker map or `nm` check in CI fails if `malloc` is linked, unless an ADR allows it during init only. cppcheck MISRA addon for Rule 21.3.

### EMB-003 · MUST · Declare ISR-shared data volatile and protect multi-byte access

Variables shared between an interrupt service routine and the main loop are `volatile`. Reads and writes of shared data wider than the CPU's atomic width happen inside a critical section or use atomic operations.

- **Why:** Without `volatile` the compiler may cache the value in a register. Without a critical section a 32-bit counter can be read half-updated on an 8- or 16-bit MCU.
- **Check:** advisory, enforced in review. ISRs are listed in the module header with the data they share.

### EMB-004 · MUST · Always use braces and handle every switch case

Every `if`, `else`, `for`, `while` and `do` body is a braced compound statement. Every `switch` has a `default` clause, and fall-through is explicit and commented.

- **Why:** Missing braces cause bugs when a second line is added. A missing `default` hides unexpected states (MISRA C Rules 15.6 and 16.4, BARR-C).
- **Check:** `clang-format` with `InsertBraces: true`; `clang-tidy` `readability-braces-around-statements` and `bugprone-switch-missing-default-case`.

### EMB-005 · MUST · Check or explicitly discard every return value

The return value of every non-void function is used or explicitly cast to `(void)` with a comment. Driver functions return an error code enum, never a bare `int`.

- **Why:** Ignored error codes are the most common cause of silent failures in firmware (MISRA C Rule 17.7).
- **Check:** `-Werror=unused-result` with `__attribute__((warn_unused_result))` on driver APIs; cppcheck MISRA addon for Rule 17.7.

### EMB-006 · MUST · Prefix public symbols with the module name and carry units

Public functions, types and macros start with the module name (`uart_init()`, `uart_config_t`, `UART_BAUD_RATE`). Physical quantities carry their unit (`supply_voltage_mv`, `timeout_ms`), per NAM-003.

- **Why:** C has one global namespace. Module prefixes prevent clashes and show where a symbol lives; units prevent off-by-1000 bugs.
- **Check:** `clang-tidy` `readability-identifier-naming` configured with the module prefix pattern.

### EMB-007 · SHOULD · Build warning-free with static analysis

Compile with `-Wall -Wextra -Werror` (STY-002), and run cppcheck with the MISRA addon and `clang-tidy` in CI on every PR.

- **Why:** Compilers and analyzers find undefined behavior that tests on one board never trigger.
- **Check:** CI job `static-analysis`; new findings block, existing findings are baselined at install (INS).

## Reference

### Example module header

```c
/* uart_driver.h */
#ifndef UART_DRIVER_H
#define UART_DRIVER_H

#include <stdbool.h>
#include <stdint.h>

#define UART_BAUD_RATE (115200U)

typedef enum
{
    UART_OK = 0,
    UART_ERR_TIMEOUT,
    UART_ERR_OVERRUN,
} uart_status_t;

typedef struct
{
    uint32_t baud_rate;
    uint16_t rx_timeout_ms;
} uart_config_t;

uart_status_t uart_init(uart_config_t const * p_config) __attribute__((warn_unused_result));
uart_status_t uart_send_byte(uint8_t byte) __attribute__((warn_unused_result));

#endif /* UART_DRIVER_H */
```

### Example .clang-tidy (excerpt)

```yaml
Checks: >
  bugprone-*,
  readability-braces-around-statements,
  readability-identifier-naming,
  -bugprone-easily-swappable-parameters
WarningsAsErrors: '*'
CheckOptions:
  - { key: readability-identifier-naming.FunctionCase, value: lower_case }
  - { key: readability-identifier-naming.TypedefSuffix, value: _t }
  - { key: readability-identifier-naming.MacroDefinitionCase, value: UPPER_CASE }
```

## Sources

- BARR-C:2018 Embedded C Coding Standard (Barr Group)
- MISRA C:2023 Guidelines for the use of the C language in critical systems (MISRA)
- [cppcheck MISRA addon](https://cppcheck.sourceforge.io/)
- [clang-tidy checks](https://clang.llvm.org/extra/clang-tidy/checks/list.html)
