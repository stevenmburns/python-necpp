### Version 1.7.4.post1:

* Linux wheels: stop vendoring libgomp (`auditwheel repair --exclude libgomp.so.1`)
  so the wheel shares the system OpenMP runtime instead of bundling a private
  copy. Fixes a static-TLS collision that silently disabled other accelerated
  extensions (e.g. momwire) co-loaded in the same process. Same source as 1.7.4;
  build-only change. Linux wheels now require a system libgomp at runtime.

### Version 1.7.3.6:

* Update with a requested fix by user slawkory in context_clean.py
* Also fix an intger division bug introduced with the shift to python3 in logperiodic_opt.py
