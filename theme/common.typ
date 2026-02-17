#import "@preview/typslides:1.3.2": *
#let primary = rgb("013220")
// Defaul slide setup
#let deck =  typslides.with(
  ratio: "16-9",
  theme: "greeny",
  font: "Noto Sans",
  font-size: 21pt,
  link-style: "color",
  show-progress: false,
)
#let code(lang, s) = raw(lang: lang, block: true, s)
#let code-file(path, lang: "text") = raw(lang: lang, block: true)[#read(path)]
#let note(body) = align(bottom+left)[#text(size: 19pt, fill: gray)[#body]]
