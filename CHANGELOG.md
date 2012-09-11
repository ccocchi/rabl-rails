# CHANGELOG

## 0.1.2
  * Add RablRails#render method (see README or source code)
  * Fix fail when JSON engine is not found. Now fallback to MultiJson.default_adapter
  * Warning message printed on logger when JSON engine fail to load

## 0.1.1

  * Add CHANGELOG
  * Remove unnused test in loop
  * Speed up rendering by not double copying variable from context
  * Rename private variable to avoid name conflict
  * Remove sqlite3 development dependency