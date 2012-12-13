
justJK = window.justJK ?= {}

Util = justJK.Util =
  echo:              (args...)          -> console.log arg for arg in args
  stringContains:    (haystack, needle) -> haystack.indexOf(needle) != -1
  stringStartsWith:  (haystack, needle) -> haystack.indexOf(needle) ==  0

