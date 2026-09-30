# uthash

The existing `uthash.h` declares version 2.3.0. The added `utarray.h` is
vendored from the upstream v2.3.0 release:

- Upstream: https://github.com/troydhanson/uthash
- Pinned commit: `e493aa90a2833b4655927598f169c31cfcdf7861`
- `utarray.h` is copied unchanged from `src/utarray.h` at that commit
- The upstream BSD license notice is retained in each header

UA2F embeds a `UT_array` for User-Agent entries beyond the eight inline slots.
`utarray_init` allocates nothing, `utarray_clear` retains overflow capacity, and
`utarray_done` frees only the overflow buffer. The inline storage is never given
to utarray. The parser's append helper overrides utarray's default fatal OOM
handling locally and restores capacity when a reserve fails.

The zero-allocation guarantee is limited to UA entry storage for at most eight
entries per parser feed. Session objects and network buffers are separate.
Overflow parser capacity is reused across feeds; NFQUEUE still allocates a
separate copy-out buffer for each payload with more than eight entries.
Allocation-count and failure-injection tests use GNU-compatible linker `--wrap`
options; production builds do not replace the allocator.
