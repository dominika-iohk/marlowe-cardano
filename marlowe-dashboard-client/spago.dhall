{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "marlowe-dashboard-client"
, dependencies =
  [ "aff"
  , "affjax"
  , "argonaut"
  , "argonaut-codecs"
  , "argonaut-core"
  , "arrays"
  , "avar"
  , "bifunctors"
  , "console"
  , "control"
  , "datetime"
  , "effect"
  , "either"
  , "enums"
  , "exceptions"
  , "filterable"
  , "foldable-traversable"
  , "foreign-object"
  , "formatters"
  , "halogen"
  , "halogen-subscriptions"
  , "http-methods"
  , "integers"
  , "json-helpers"
  , "lists"
  , "maybe"
  , "newtype"
  , "now"
  , "ordered-collections"
  , "partial"
  , "prelude"
  , "profunctor-lenses"
  , "psci-support"
  , "remotedata"
  , "servant-support"
  , "strings"
  , "transformers"
  , "tuples"
  , "type-equality"
  , "unfoldable"
  , "unicode"
  , "uuid"
  , "web-common"
  , "web-dom"
  , "web-html"
  , "web-socket"
  ]
, packages = ../packages.dhall
, sources =
  [ "src/**/*.purs"
  , "test/**/*.purs"
  , "generated/**/*.purs"
  , "../web-common-marlowe/src/**/*.purs"
  ]
}
