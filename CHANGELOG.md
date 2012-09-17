# CHANGELOG

## 0.2.0 (unrelased)
  * Default template to render with responder can be set per controller
  * Reponder works out of the box with devise
  * object or collection can be skipped if use with `respond_to` blocks

## 0.1.3
  * Render correcly when variables are not passed via the assigns ivar but as helper methods
    (decent_exposure, focused_controller)
  * Add custom Responder

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