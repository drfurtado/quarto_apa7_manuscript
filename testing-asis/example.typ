// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}

//#assert(sys.version.at(1) >= 11 or sys.version.at(0) > 0, message: "This template requires Typst Version 0.11.0 or higher. The version of Quarto you are using uses Typst version is " + str(sys.version.at(0)) + "." + str(sys.version.at(1)) + "." + str(sys.version.at(2)) + ". You will need to upgrade to Quarto 1.5 or higher to use apaquarto-typst.")

// counts how many appendixes there are
#let appendixcounter = counter("appendix")
// make latex logo
// https://github.com/typst/typst/discussions/1732#discussioncomment-6566999
#let TeX = style(styles => {
  set text(font: ("New Computer Modern", "Times", "Times New Roman"))
  let e = measure("E", styles)
  let T = "T"
  let E = text(1em, baseline: e.height * 0.31, "E")
  let X = "X"
  box(T + h(-0.15em) + E + h(-0.125em) + X)
})
#let LaTeX = style(styles => {
  set text(font: ("New Computer Modern", "Times", "Times New Roman"))
  let a-size = 0.66em
  let l = measure("L", styles)
  let a = measure(text(a-size, "A"), styles)
  let L = "L"
  let A = box(scale(x: 105%, text(a-size, baseline: a.height - l.height, "A")))
  box(L + h(-a.width * 0.67) + A + h(-a.width * 0.25) + TeX)
})

#let firstlineindent=0.5in

// documentmode: man
#let man(
  title: none,
  runninghead: none,
  margin: (x: 1in, y: 1in),
  paper: "us-letter",
  font: ("Times", "Times New Roman"),
  fontsize: 12pt,
  leading: 18pt,
  spacing: 18pt,
  firstlineindent: 0.5in,
  toc: false,
  lang: "en",
  cols: 1,
  doc,
) = {

  set page(
    paper: paper,
    margin: margin,
    header-ascent: 50%,
    header: grid(
      columns: (9fr, 1fr),
      align(left)[#upper[#runninghead]],
      align(right)[#counter(page).display()]
    )
  )


 
if sys.version.at(1) >= 11 or sys.version.at(0) > 0 {
  set table(    
    stroke: (x, y) => (
        top: if y <= 1 { 0.5pt } else { 0pt },
        bottom: .5pt,
      )
  )
}
  set par(
    justify: false, 
    leading: leading,
    first-line-indent: firstlineindent
  )

  // Also "leading" space between paragraphs
  set block(spacing: spacing, above: spacing, below: spacing)

  set text(
    font: font,
    size: fontsize,
    lang: lang
  )

  show link: set text(blue)

  show quote: set pad(x: 0.5in)
  show quote: set par(leading: leading)
  show quote: set block(spacing: spacing, above: spacing, below: spacing)
  // show LaTeX
  show "TeX": TeX
  show "LaTeX": LaTeX

  // format figure captions
  show figure.where(kind: "quarto-float-fig"): it => [
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2)[#it.supplement #it.counter.display()]
    ]
    #par[#emph[#it.caption.body]]
    #align(center)[#it.body]
  ]
  
  // format table captions
  show figure.where(kind: "quarto-float-tbl"): it => [
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2)[#it.supplement #it.counter.display()]
    ]
    #par[#emph[#it.caption.body]]
    #block[#it.body]
  ]

 // Redefine headings up to level 5 
  show heading.where(
    level: 1
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(center)
    #set text(size: fontsize)
    #it.body
  ]
  
  show heading.where(
    level: 2
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #set text(size: fontsize)
    #it.body
  ]
  
  show heading.where(
    level: 3
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #set text(size: fontsize, style: "italic")
    #it.body
  ]

  show heading.where(
    level: 4
  ): it => text(
    size: 1em,
    weight: "bold",
    it.body
  )

  show heading.where(
    level: 5
  ): it => text(
    size: 1em,
    weight: "bold",
    style: "italic",
    it.body
  )

  if cols == 1 {
    doc
  } else {
    columns(cols, gutter: 4%, doc)
  }


}
#show: document => man(
  runninghead: "TEMPLATE FOR THE APAQUARTO EXTENSION",
  lang: "en",
  document,
)


\
\
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Using Quarto to Generate Documents in APA Style \(7th Edition)
]
)
]
#set align(center)
#block[
\
Ana Fulano#super[1];, Blanca Zutano#super[1];, Carina Mengano#super[2,3];, and Dolorita C. Perengano#super[4]

#super[1];Clinical Psychology Program, Department of Psychology, Ana and Blanca’s University

#super[2];Carina’s Primary Affiliation

#super[3];Carina’s Secondary Affiliation

#super[4];Buffalo, NY

]
#set align(left)
\
\
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Author Note
]
)
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Ana Fulano #box(width: 4.23mm, image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg")) http:\/\/orcid.org/0000-0000-0000-0001

Blanca Zutano #box(width: 4.23mm, image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg")) http:\/\/orcid.org/0000-0000-0000-0002

Carina Mengano #box(width: 4.23mm, image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg")) http:\/\/orcid.org/0000-0000-0000-0003

Dolorita C. Perengano #box(width: 4.23mm, image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg")) http:\/\/orcid.org/0000-0000-0000-0004

Carina Mengano is now at Generic University.

The authors have no conflicts of interest to disclose.

Author roles were classified using the Contributor Role Taxonomy \(CRediT; https:\/\/credit.niso.org/) as follows: #emph[Ana Fulano];#strong[: ];conceptualization and writing – original draft. #emph[Blanca Zutano];#strong[: ];project administration and formal analysis. #emph[Carina Mengano];#strong[: ];formal analysis and writing – original draft. #emph[Dolorita C. Perengano];#strong[: ];writing – original draft, methodology, and formal analysis

Correspondence concerning this article should be addressed to Ana Fulano, Clinical Psychology Program, Department of Psychology, Ana and Blanca’s University, 1234 Capital St., Albany, NY 12084-1234, USA, Email: sm\@example.org

#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Abstract
]
)
]
#block[
This document is a template demonstrating the apaquarto format.

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#emph[Keywords];: keyword1, keyword2, keyword3

#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Using Quarto to Generate Documents in APA Style \(7th Edition)
]
)
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
This is my introductory paragraph. The title will be placed above it automatically. #emph[Do not start with an introductory heading] \(e.g., "Introduction"). The title acts as your Level 1 heading for the introduction.

Details about writing headings with markdown in APA style are #link("https://wjschne.github.io/apaquarto/writing.html#headings-in-apa-style")[here];.

== Displaying Figures
<displaying-figures>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
A reference label for a figure must have the prefix `fig-`, and in a code chunk, the caption must be set with `fig-cap`. Captions are in #link("https://apastyle.apa.org/style-grammar-guidelines/capitalization/title-case")[title case];.

#block[
#block[
#figure([
#box(width: 162.0pt, image("example_files/figure-typst/fig-myplot-1.svg"))
], caption: figure.caption(
position: top, 
[
The Figure Caption
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-myplot>


]
]
#block[
#emph[Note];. This is the note below the figure.

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
To refer to any figure or table, use the `@` symbol followed by the reference label \(e.g., #link(<fig-myplot>)[Figure~1];).

== Imported Graphics
<imported-graphics>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
One way to import an existing graphic as a figure is to use `knitr::include_graphics` in a code chunk. For example, #link(<fig-import1>)[Figure~2] is an imported image. Note that in apaquarto-pdf documents, we can specify that that a figure or table should span both columns when in journal mode by setting the `apa-twocolumn` chunk option to `true`. For other formats, this distinction does not matter.

#block[
#block[
#figure([
#box(width: 48%,image("sampleimage.png"))
], caption: figure.caption(
position: top, 
[
An Imported Graphic
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-import1>


]
]
#block[
#emph[Note];. A note below the figure

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Figure graphics can be imported directly with Markdown, as with #link(<fig-import2>)[Figure~3];.

#figure([
#box(width: 49%,image("sampleimage.png"))
], caption: figure.caption(
position: top, 
[
Another Way to Import Graphics
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-import2>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Which style of creating figures you choose depends on preference and need.

== Displaying Tables
<displaying-tables>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We can make a table the same way as a figure. Generating a table that conforms to APA format in all document formats can be tricky. When the table is simple, the `kable` function from knitr works well. Feel free to experiment with different methods, but I have found that David Gohel’s #link("https://davidgohel.github.io/flextable/")[flextable] to be the best option when I need something more complex.

#block[
#figure([
#block[
#figure(
align(center)[#table(
  columns: 2,
  align: (col, row) => (right,left,).at(col),
  inset: 6pt,
  [Numbers], [Letters],
  [1],
  [A],
  [2],
  [B],
  [3],
  [C],
  [4],
  [D],
)]
)

]
], caption: figure.caption(
position: top, 
[
The Table Caption
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
numbering: "1", 
)
<tbl-mytable>


]
#block[
#emph[Note];. The note below the table.

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
To refer to this table in text, use the `@` symbol followed by the reference label like so: As seen in #link(<tbl-mytable>)[Table~1];, the first few numbers and letters of the alphabet are displayed.

In {tbl-mytable2}, there are some numbers.

#figure([
#figure(
align(center)[#table(
  columns: 4,
  align: (col, row) => (auto,left,right,center,).at(col),
  inset: 6pt,
  [Default], [Left], [Right], [Center],
  [12],
  [12],
  [12],
  [12],
  [123],
  [123],
  [123],
  [123],
  [1],
  [1],
  [1],
  [1],
)]
)

], caption: figure.caption(
position: top, 
[
My Table
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
numbering: "1", 
)
<tbl-mytable2>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
What if you want the tables and figures to be at the end of the document? In the .pdf format, you can set the `floatsintext` option to false. For .html and .docx documents, there is not yet an automatic way to put tables and figures at the end. You can, of course, just put them all at the end, in order. The reference labels will work no matter where they are in the text.

== Tables and Figures Spanning Two Columns in Journal Mode
<tables-and-figures-spanning-two-columns-in-journal-mode>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
When creating tables and figures in journal mode, care must be taken not to make figures and tables wider than the columns, otherwise LaTeX sometimes makes them disappear.

As demonstrated in #link(<fig-twocolumn>)[Figure~4];, you can make figures tables span the two columns by setting the `apa-twocolumn` chunk option to `true`.

#block[
#block[
#figure([
#box(width: 345.0pt, image("example_files/figure-typst/fig-twocolumn-1.svg"))
], caption: figure.caption(
position: top, 
[
A Figure Spanning Two Columns When in Journal Mode
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-twocolumn>


]
]
#block[
#emph[Note];. Figures in two-column mode are only different for jou mode in .pdf documents

]
== Math and Equations
<math-and-equations>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Inline math uses LaTeX syntax with single dollar signs. For example, the reliability coefficient of my measure is $r_(X X) = .95$.

If you want to display and refer to a specific formula, enclose the formula in two dollar signs. After the second pair of dollar signs, place the label in curly braces. The label should have an `#eq-` prefix. To refer to the formula, use the same label but with the `@` symbol. For example, @eq-euler is Euler’s Identity, which is much admired for its elegance.

== Citations
<citations>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
See #link("https://quarto.org/docs/authoring/footnotes-and-citations.html")[here] for instructions on setting up citations and references.

A parenthetical citation requires square brackets \(#link(<ref-CameronTrivedi2013>)[Cameron & Trivedi, 2013];). This reference was in my bibliography file. An in-text citation is done like so:

Cameron and Trivedi \(#link(<ref-CameronTrivedi2013>)[2013];) make some important points …

See #link("https://wjschne.github.io/apaquarto/writing.html#references")[here] for explanations, examples, and citation features exclusive to apaquarto. For example, apaquarto can automatically handle possessive citations:

Schneider and McGrew’s \(#link(<ref-schneider2012cattell>)[2012];) position was …

== Masking Author Identity for Peer Review
<masking-author-identity-for-peer-review>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Setting `mask` to `true` will remove author names, affiliations, and correspondence from the title page. Any references listed in the `masked-citations` field will be masked as well. See #link("https://wjschne.github.io/apaquarto/writing.html#masked-citations-for-anonymous-peer-review")[here] for more information.

#math.equation(block: true, numbering: "(1)", [ $ e^(i pi) + 1 = 0 $ ])<eq-euler>

== Block Quotes
<block-quotes>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Sometimes you want to give a longer quote that needs to go in its own paragraph. Block quotes are on their own line starting with the \> character. For example, Austen’s \(#link(<ref-austenMansfieldPark1990>)[1814/1990];) #emph[Mansfield Park] has some memorable insights about the mind:

#quote(block: true)[
If any one faculty of our nature may be called more wonderful than the rest, I do think it is memory. There seems something more speakingly incomprehensible in the powers, the failures, the inequalities of memory, than in any other of our intelligences. The memory is sometimes so retentive, so serviceable, so obedient; at others, so bewildered and so weak; and at others again, so tyrannic, so beyond control! We are, to be sure, a miracle every way; but our powers of recollecting and of forgetting do seem peculiarly past finding out. \(p.~163)
]

#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
If your quote has multiple paragraphs, like this passage from Brown \(#link(<ref-brownHowKilledPluto2012>)[2012];), separate them with a lone `>` character between the lines:

#quote(block: true)[
In the entire field of astronomy, there is no word other than #emph[planet] that has a precise, lawyerly definition, in which certain criteria are specifically enumerated. Why does #emph[planet] have such a definition but #emph[star];, #emph[galaxy];, and #emph[giant molecular cloud] do not? Because in astronomy, as in most sciences, scientists work by concepts rather than by definitions. The concept of a star is clear; a star is a collection of gas with fusion reactions in the interior giving off energy. A galaxy is a large, bound collection of stars. A giant molecular cloud is a giant cloud of molecules. The concept of a planet—in the eight-planet solar system—is equally simple to state. A planet is a one of a small number of bodies that dominate a planetary system. That is a concept, not a definition. How would you write that down in a precise definition?

I wouldn’t. Once you write down a definition with lawyerly precision, you get the lawyers involved in deciding whether or not your objects are planets. Astronomers work in concepts. We rarely call in the attorneys for adjudication. \(p.~242)
]

== Hypotheses, Aims, and Objectives
<hypotheses-aims-and-objectives>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The last paragraph of the introduction usually states the specific hypotheses of the study, often in a way that links them to the research design.

= Method
<method>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
General remarks on method. This paragraph is optional.

Not all papers require each of these sections. Edit them as needed. Consult the #link("https://apastyle.apa.org/jars")[Journal Article Reporting Standards] for what is needed for your type of article.

== Participants
<participants>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Who are they? How were they recruited? Report criteria for participant inclusion and exclusion. Perhaps some basic demographic stats are in order. A table is a great way to avoid repetition in statistical reporting.

== Measures
<measures>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
This section can also be titled #strong[Materials] or #strong[Apparatus];. Whatever tools, equipment, or measurement devices used in the study should be described.

=== Measure A
<measure-a>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Describe Measure A.

=== Measure B
<measure-b>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Describe Measure B.

==== Subscale B1.
<subscale-b1>
A paragraph after a 4th-level header will appear on the same line as the header.

==== Subscale B2.
<subscale-b2>
A paragraph after a 4th-level header will appear on the same line as the header.

===== Subscale B2a.
<subscale-b2a>
A paragraph after a 5th-level header will appear on the same line as the header.

===== Subscale B2b.
<subscale-b2b>
A paragraph after a 5th-level header will appear on the same line as the header.

== Procedure
<procedure>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
What did participants do? How are the data going to be analyzed?

= Results
<results>
== Descriptive Statistics
<descriptive-statistics>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Describe the basic characteristics of the primary variables. My ideal is to describe the variables well enough that someone conducting a meta-analysis can include the study without needing to ask for additional information.

= Discussion
<discussion>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Describe results in non-statistical terms.

== Limitations and Future Directions
<limitations-and-future-directions>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Every study has limitations. Based on this study, some additional steps might include…

== Conclusion
<conclusion>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Describe the main point of the paper.

= References
<references>
#set par(first-line-indent: 0in, hanging-indent: 0.5in)
#block[
#block[
Austen, J. \(1990). #emph[Mansfield Park];. Oxford University Press. \(Original work published 1814)

] <ref-austenMansfieldPark1990>
#block[
Brown, M. \(2012). #emph[How I killed Pluto and why it had it coming];. Spiegel & Grau.

] <ref-brownHowKilledPluto2012>
#block[
Cameron, A. C., & Trivedi, P. K. \(2013). #emph[Regression analysis of count data] \(2nd ed.). Cambridge University Press. #link("https://doi.org/10.1017/CBO9781139013567")

] <ref-CameronTrivedi2013>
#block[
Schneider, W. J., & McGrew, K. S. \(2012). #emph[The Cattell-Horn-Carroll model of intelligence.]

] <ref-schneider2012cattell>
] <refs>
#set par(first-line-indent: 0.5in, hanging-indent: 0in)
#pagebreak(weak: true)
= Appendix
<appendix>
#counter(figure.where(kind: "quarto-float-fig")).update(0)
#counter(figure.where(kind: "quarto-float-tbl")).update(0)
#appendixcounter.step()
= The Title for Appendix
<the-title-for-appendix>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
If there are multiple appendices, label them with level 1 headings as Appendix A, Appendix B, and so forth.

Tables and figures in the first appendix automatically get the prefix "A", and the numbering starts again at 1. See #link(<fig-appendfig>)[Figure~A1];.

If there were a second appendix, tables and figures would get the prefix "B", and the numbering starts again at 1. Make as many appendices as needed.

#figure([
#box(width: 506.6387434554974pt, image("sampleimage.png"))
], caption: figure.caption(
position: top, 
[
Appendix Figure
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-appendfig>





