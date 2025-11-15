// This is a Quarto template for Typst
#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 0.8in, y: 1in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  
  set page(
    paper: paper,
    margin: (x: 0.8in, bottom: 1in, top: 0.5in),
    numbering: "1",
    number-align: center,
    footer: {
      rect(
        width: 100%,
        height: 0.75in,
        outset: (x: 15%),
        fill: rgb("#68ACE5"),
        pad(top: 16pt, block(width: 100%, fill: rgb("#68ACE5"), [
          #grid(
            columns: (3fr, auto, 1fr),
            align(left)[#text(title, fill: white, weight: 600, font: ("Georgia", "Times New Roman"), size: 9pt)],
            align(center)[],
            align(right)[#text(date, fill: white, weight: 600, font: ("Georgia", "Times New Roman"), size: 9pt)],
          )
        ])),
      )
    },
  )
  
  set text(
    font: ("Arial", "Liberation Sans", "DejaVu Sans"),
    size: fontsize,
    lang: lang,
    region: region,
  )
  
  set par(justify: true)
  
  // Configure heading styles
  show heading.where(level: 1): it => {
    set text(size: 16pt, fill: rgb("#002D72"), font: ("Georgia", "Times New Roman"), weight: "bold")
    v(0.5em)
    it
    v(0.3em)
  }
  
  show heading.where(level: 2): it => {
    set text(size: 14pt, font: ("Georgia", "Times New Roman"), weight: "bold")
    v(0.5em)
    it
    v(0.3em)
  }
  
  show heading.where(level: 3): it => {
    set text(size: 13pt, font: ("Georgia", "Times New Roman"), weight: "bold")
    v(0.4em)
    it
    v(0.2em)
  }
  
  show heading.where(level: 4): it => {
    set text(size: 12pt, font: ("Georgia", "Times New Roman"), weight: "bold")
    v(0.3em)
    it
    v(0.2em)
  }
  
  // Configure links
  show link: set text(fill: rgb("#002D72"))
  
  // Configure code blocks
  show raw.where(block: true): it => {
    set text(size: 9pt)
    block(
      width: 100%,
      fill: rgb("#f5f5f5"),
      inset: 8pt,
      radius: 4pt,
      it
    )
  }
  
  show raw.where(block: false): it => {
    box(
      fill: rgb("#f5f5f5"),
      inset: (x: 3pt, y: 0pt),
      outset: (y: 3pt),
      radius: 2pt,
      it
    )
  }
  
  // Blue line helper
  let blueline() = {
    line(length: 100%, stroke: 2pt + rgb("#68ACE5"))
  }
  
  // Title page header
  stack(
    // Logo
    place(dx: 0in, dy: 0.25in, align(horizon, block(width: 100%, [
      #image("imgs/d4d.jpg", width: 100%)
    ]))),
    
    // Blue line separator
    place(dx: 0in, dy: 1.2in, align(block([
      #blueline()
    ]))),
    
    // Title
    place(dx: 0in, dy: 1.45in, align(block(width: 100%, [
      #text(
        fill: rgb(255, 255, 255), 
        weight: "bold", 
        size: 20pt, 
        font: ("Georgia", "Times New Roman"),
        title
      )
    ]))),
    
    // Subtitle
    if subtitle != none {
      place(dx: 0in, dy: 2.0in, align(block(width: 100%, [
        #text(
          fill: rgb(255, 255, 255), 
          weight: "regular", 
          size: 16pt, 
          font: ("Georgia", "Times New Roman"),
          style: "italic",
          subtitle
        )
      ])))
    },
    
    // Authors
    if authors != none {
      place(dx: 0.4in, dy: if subtitle != none { 2.5in } else { 2.2in }, align(block(width: 100%, [
        #for author in authors [
          #text(size: 12pt, weight: "medium", author.name)
          #if "affiliation" in author [
            #linebreak()
            #text(size: 11pt, style: "italic", author.affiliation)
          ]
          #v(0.3em)
        ]
      ])))
    },
  )
  
  v(if subtitle != none { 3.2in } else { 2.8in })
  blueline()
  v(0.5em)
  
  // Table of contents
  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
      #outline(
        title: toc_title,
        depth: toc_depth,
        indent: toc_indent
      );
    ]
  }
  
  // Main document body
  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
