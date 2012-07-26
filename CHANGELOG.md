# CHANGELOG

## 0.1.2 (unreleased)
  * Add RablRails#render method (see README or source code)
  * Fix fail when JSON engine is not found. Now fallback to MultiJson.default_adapter

## 0.1.1

  * Add CHANGELOG
  * Remove unnused test in loop
  * Speed up rendering by not double copying variable from context
  * Rename private variable to avoid name conflict
  * Remove sqlite3 development dependency