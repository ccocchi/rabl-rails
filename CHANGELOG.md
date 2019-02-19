# CHANGELOG

## 0.5.5
  * Add `lookup` node

## 0.5.4
  * Relax concurrent-ruby version dependency (javierjulio)

## 0.5.3
  * Allow `extends` to accept lambdas

## 0.5.2
  * Add `const` node

## 0.5.1
  * Fix bug when trying to compile partials with caching enabled

## 0.5.0
  * Add requirement ruby >= 2.2
  * Drop support for Rails < 4.2
  * Replace `thread_safe` with `concurrent_ruby`
  * Remove custom responder
  * Remove rendering outside of Rails
  * Improve Rails 5 compatibility

## 0.4.3
  * Fix custom responder compatibility with responders 2.1 (itkin)
  * Fix bug when template was already loaded by ActionView and causing a nil
    error

## 0.4.2
  * Allow to pass locals to partials
  * Add condition to `attributes`

## 0.4.1
  * Make classes that should not be treated as collection configurable
  * Internal change to determine rendering format

## 0.4.0
  * Internal cleanup and refactor
  * Remove the `allow_empty_format_in_template` option, since it has become
    the default behavior.
  * Remove multi_json dependency
  * New options available
    * replace_nil_values_with_empty_strings
    * replace_empty_string_values_with_nil
    * exclude_nil_values

## 0.3.4
  * Add `xml_options` option to root_level (brettallred)

  * Format can be omitted in template filename

      RablRails.allow_empty_format_in_template = true
      RablRails.render(user, 'show') # => app/view/user.rabl

  * Rails 4 support
  * Update travis configuration and remove warning in tests (petergoldstein)

## 0.3.3
  * Add response caching

## 0.3.2
  * Using child with a nil value will be correctly formatted as nil
  * Allow controller's assigns to have symbol keys
  * Does not modify in place format extracted from context
  * Add JSONP support

## 0.3.1
  * Add `merge` keywork
  * Format can be passed as a string or a symbol
  * Avoid to unexpectedly change cached templates (johnbintz)
  * Add full template stack support to `glue` (fnordfish)
  * Allow format to be a symbol (lloydmeta)

## 0.3.0
  * Travis integration
  * Add test for keywords used as variable names
  * Add PList renderer
  * Remove location header from post responses in responder
  * Fix bug with incomplete template prefixing

## 0.2.2
  * Add condition blocks

## 0.2.1
  * Avoid useless render on POST request with custom responder
  * Custom responder now fallback to Rails default in case the template is not found

## 0.2.0
  * Add `root` in DSL to set root without changing the data source
  * Add XML renderer
  * Use MultiJson's preferred JSON engine as default (shmeltex)
  * Default template to render with responder can be set per controller
  * Reponder works out of the box with devise
  * object or collection can be skipped if use with `respond_to` blocks

## 0.1.3
  * Render correctly when variables are not passed via the assigns ivar but as helper methods
    (decent_exposure, focused_controller)
  * Add custom Responder

## 0.1.2
  * Add RablRails#render method (see README or source code)
  * Fix fail when JSON engine is not found. Now fallback to MultiJson.default_adapter
  * Warning message printed on logger when JSON engine fail to load

## 0.1.1
  * Add CHANGELOG
  * Remove unused test in loop
  * Speed up rendering by not double copying variable from context
  * Rename private variable to avoid name conflict
  * Remove sqlite3 development dependency
