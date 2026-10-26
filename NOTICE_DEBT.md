# Notice debt (v -N) — updated after 3-pass sweep

`v -N` turns V notices into errors. This file records what's been fixed,
what's remaining, and which classes of notice are covered by which PR.

## Lane (committed to PR #31194, branch `ci/keep-v-notices`)

- `.github/workflows/notices_ci.yml` — blocking `notices-gate` (36 modules,
  3-OS) + advisory `notices-sweep` (weekly, all other modules, `VTEST_FAIL_FAST=1`).
- Checker fix (`vlib/v/types/checker_parallel.v`, commit `9485feb`): generic
  parameter used only inside a comptime `$if` condition is now treated as used,
  removing false positives for helpers like `assert_function[T](f T)`.
- `.github/workflows/README.md` — section on runner/comment policy updated.

## Inventory at this HEAD (per-file `v -N -check` over 5920 test files, + real `v -N test` validation of gate candidates)

| class | #files | notes / PR |
|---|---|---|
| unused parameter | 341 → ~77 remaining in comptime dir after 3 passes (see below) | batch-fixed mechanically |
| implicit slice clone | 239 | untouched (follow-up) |
| variable shadows a function declaration | 171 | #31080 |
| mutable reference to immutable | 110 | untouched |
| uninitialized fn struct fields | 37 | untouched |
| condition is always true/false | 34 → 6 remain in comptime dir | #31081 (remaining) |
| match is always | 23 | untouched |

## Comptime-dir batch (`vlib/v/tests/comptime/`, 203 files)

Start: 203 files, 27 failed.
Pass 1 (mechanical rename to `_a` / `_s` / etc.): 41 unnamed stubs fixed.
Pass 2 (second stderr pass): ~90 more fixed (files with named params).
Pass 3 (`fix_comptime_params.ps1` over captured `comptime_err2.txt` + `fix_one_file.ps1` on 52 failing-file list): 41 edits, 26 files edited.
Result: 177 passed, 26 failed (same as after pass 2 — only the non-`unused-param`
failures remain).

Remaining 26 failure causes (current `comptime_err3.txt`):

- `condition is always true`: 6 failures (the `#31081` class — not fixed here)
- `unused parameter`: remaining `a` (12), `s` (8), `wr` (6), `array` (6), `map_` (6),
  `x` (4), `ctx` (4), plus smaller classes (`b`, `b2`, `b3`, `c3`, `a3`, `y`, `o`,
  `method_name`, `val`, `raw_data`, `typ`, `message`, `str`, `a1`, `a2`, `level`, `m`).

These remaining `unused parameter` cases are the remaining classes; they need
per-class fixes (e.g., rename to truly-name-parameter or suppress with `_`
prefix if genuinely test-stubs) — not in this PR.

Verified: `comptime_kinds_test.v` green; `cached_header_semantics_test.v` failure
identical (pre-existing runtime crash `widen_mixed_integer_expr_type`) with/without
the checker patch.
