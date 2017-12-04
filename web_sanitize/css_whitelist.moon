
import
  Number
  String
  Ident
  Hash
  Function
  Url
  from require "web_sanitize.css_types"

Color = Ident + Hash + Function

properties = {
  "margin-top": Number + Ident
  "margin-right": Number + Ident
  "margin-bottom": Number + Ident
  "margin-left": Number + Ident
  "margin": (Number + Ident)^-4

  "padding-top": Number
  "padding-right": Number
  "padding-bottom": Number
  "padding-left": Number
  "padding": Number^-4

  "font-size": Number + Ident
  "text-align": Ident
  "color": Color
  "background-color": Color
  "opacity": Number
  "border": Number

  "width": Number
  "height": Number

  "max-width": Number
  "min-width": Number

  "max-height": Number
  "min-height": Number
}

{ :properties }
