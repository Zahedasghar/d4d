// ============================================================
//  PBS Trade Statistics — Typst Template
//  Pakistan Bureau of Statistics | Government of Pakistan
// ============================================================

#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 0.75in, y: 1in),
  paper: "a4",
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

  // ── Colour palette ────────────────────────────────────────
  let pbs-green      = rgb("#1a4a2e")
  let pbs-green-mid  = rgb("#2c5a3e")
  let pbs-gold       = rgb("#b89a3b")
  let pbs-gold-pale  = rgb("#f9f4e6")
  let pbs-cream      = rgb("#fdfaf4")
  let pbs-text       = rgb("#1e2d1e")
  let pbs-muted      = rgb("#5a6a5a")
  let dec-red        = rgb("#c0392b")
  let inc-green      = rgb("#1a6b3a")
  let imp-dark       = rgb("#6b2020")
  let bot-dark       = rgb("#2e3a1a")

  // ── Page setup (inner pages) ───────────────────────────────
  set page(
    paper: paper,
    margin: (x: 0.75in, top: 0.85in, bottom: 1in),
    background: rect(width: 100%, height: 100%, fill: rgb("#f0ece2")),
    numbering: "1",
    number-align: center,

    header: context {
      if counter(page).get().first() > 1 {
        block(
          width: 100%,
          fill: pbs-cream,
          inset: (x: 0pt, top: 4pt, bottom: 4pt),
          [
            #line(length: 100%, stroke: 2pt + pbs-green)
            #v(2pt)
            #grid(
              columns: (1fr, auto, 1fr),
              align(left)[
                #text(size: 8pt, fill: pbs-muted, font: ("Georgia", "Times New Roman"),
                  [Pakistan Bureau of Statistics])
              ],
              align(center)[
                #text(size: 8pt, fill: pbs-green, weight: "bold",
                  font: ("Georgia", "Times New Roman"),
                  [Advance Release — External Trade Statistics])
              ],
              align(right)[
                #text(size: 8pt, fill: pbs-muted, font: ("Georgia", "Times New Roman"),
                  [February, 2026])
              ],
            )
            #v(2pt)
            #line(length: 100%, stroke: 0.8pt + pbs-gold)
          ]
        )
      }
    },

    footer: context {
      block(
        width: 100%,
        fill: pbs-green,
        inset: (x: 12pt, y: 6pt),
        [
          #grid(
            columns: (2fr, 1fr),
            align(left)[
              #text(size: 8pt, fill: white, font: ("Georgia", "Times New Roman"),
                [Pakistan Bureau of Statistics | Government of Pakistan | www.pbs.gov.pk])
            ],
            align(right)[
              #text(size: 8pt, fill: white, font: ("Georgia", "Times New Roman"),
                [Page #counter(page).display("1")])
            ],
          )
        ]
      )
    },
  )

  // ── Base text ─────────────────────────────────────────────
  set text(
    font: ("Georgia", "Times New Roman", "Linux Libertine"),
    size: fontsize,
    lang: lang,
    region: region,
    fill: pbs-text,
  )

  set par(justify: true, leading: 0.68em)

  // ── Figures stay inline — no floating ─────────────────────
  show figure: set figure(placement: none)
  show figure: it => { v(0.3em); it; v(0.1em) }

  // ── Heading styles ────────────────────────────────────────
  // FIX: block(sticky:true) prevents any heading being
  // stranded alone at the bottom of a page.

  show heading.where(level: 2): it => {
    block(sticky: true)[
      #v(0.5em)
      #block(
        width: 100%,
        fill: if it.body == [EXPORTS]          { pbs-green }
              else if it.body == [IMPORTS]      { imp-dark  }
              else if it.body == [BALANCE OF TRADE] { bot-dark }
              else                              { pbs-green },
        inset: (left: 14pt, right: 10pt, top: 6pt, bottom: 6pt),
        below: 0.35em,
        [
          #box(width: 4pt, height: 100%, fill: pbs-gold)
          #h(6pt)
          #text(
            fill: white,
            size: 11pt,
            weight: "bold",
            font: ("Georgia", "Times New Roman"),
            tracking: 1.5pt,
            upper(it.body)
          )
        ]
      )
    ]
  }

  show heading.where(level: 3): it => {
    block(sticky: true)[
      #v(0.35em)
      #text(
        fill: pbs-green,
        size: 10.5pt,
        weight: "bold",
        font: ("Georgia", "Times New Roman"),
        it.body
      )
      #v(0.04em)
      #line(length: 100%, stroke: 1pt + pbs-gold)
      #v(0.18em)
    ]
  }

  show heading.where(level: 4): it => {
    block(sticky: true)[
      #v(0.28em)
      #text(fill: pbs-green, size: 10pt, weight: "bold",
        font: ("Georgia", "Times New Roman"), it.body)
      #v(0.12em)
    ]
  }

  // ── Links ─────────────────────────────────────────────────
  show link: set text(fill: pbs-green)

  // ── Horizontal rules ──────────────────────────────────────
  show line: it => { v(0.1em); it; v(0.1em) }

  // ══════════════════════════════════════════════════════════
  // COVER PAGE
  // ══════════════════════════════════════════════════════════
  page(
    paper: paper,
    margin: (x: 0pt, top: 0pt, bottom: 0pt),
    numbering: none,
    background: rect(width: 100%, height: 100%, fill: rgb("#f0ece2")),
    footer: none,
    header: none,
  )[

    #rect(width: 100%, height: 12pt, fill: pbs-green)
    #rect(width: 100%, height: 3pt,
      fill: gradient.linear(pbs-green, pbs-gold, pbs-green, angle: 0deg))

    // ── Dual-logo header strip ─────────────────────────────
    #block(width: 100%, fill: pbs-cream,
      inset: (x: 0.75in, top: 16pt, bottom: 12pt),
    )[
      #grid(
        columns: (auto, 1fr, auto),
        column-gutter: 16pt,
        align: horizon,
        box(width: 64pt, height: 64pt, clip: true, radius: 50%,
          stroke: 2pt + pbs-gold,
          image("imgs/pbs_logo.png", width: 64pt, height: 64pt, fit: "cover")),
        align(center)[
          #text(size: 8pt, fill: pbs-muted, tracking: 2pt,
            font: ("Georgia", "Times New Roman"), upper[Government of Pakistan])
          #v(3pt)
          #text(size: 18pt, weight: "bold", fill: pbs-green,
            font: ("Georgia", "Times New Roman"))[Pakistan Bureau of Statistics]
          #v(2pt)
          #text(size: 9.5pt, style: "italic", fill: pbs-gold,
            font: ("Georgia", "Times New Roman")
          )[Ministry of Planning, Development and Special Initiatives]
          #v(4pt)
          #box(stroke: 0.8pt + pbs-gold, fill: pbs-gold-pale,
            inset: (x: 14pt, y: 4pt), radius: 2pt,
          )[
            #text(size: 7.5pt, fill: pbs-gold, tracking: 2pt,
              font: ("Georgia", "Times New Roman"),
              upper[Advance Release · Trade Statistics · 2026])
          ]
        ],
        box(width: 64pt, height: 64pt, clip: true, radius: 50%,
          stroke: 2pt + pbs-gold,
          image("imgs/mopd_logo.png", width: 64pt, height: 64pt, fit: "cover")),
      )
    ]

    #rect(width: 100%, height: 3pt,
      fill: gradient.linear(pbs-green, pbs-gold, pbs-green, angle: 0deg))

    // ── Title band ────────────────────────────────────────
    #block(width: 100%, fill: pbs-green,
      inset: (x: 0.75in, top: 24pt, bottom: 20pt),
    )[
      #box(width: 6pt, height: 40pt, fill: pbs-gold)
      #h(12pt)
      #stack(
        spacing: 6pt,
        text(size: 21pt, weight: "bold", fill: white,
          font: ("Georgia", "Times New Roman"), title),
        if subtitle != none {
          text(size: 13pt, style: "italic", fill: pbs-gold,
            font: ("Georgia", "Times New Roman"), subtitle)
        }
      )
    ]

    // ── Meta strip ────────────────────────────────────────
    #block(width: 100%, fill: pbs-cream,
      inset: (x: 0.75in, top: 12pt, bottom: 12pt),
    )[
      #grid(
        columns: (1fr, 1fr, 1fr),
        [
          #text(size: 8pt, fill: pbs-muted, tracking: 1pt, upper[Date])\
          #text(size: 10pt, fill: pbs-text, weight: "bold",
            font: ("Georgia", "Times New Roman"), date)
        ],
        align(center)[
          #text(size: 8pt, fill: pbs-muted, tracking: 1pt, upper[Release])\
          #text(size: 10pt, fill: pbs-text, weight: "bold",
            font: ("Georgia", "Times New Roman"), [Provisional Figures])
        ],
        align(right)[
          #text(size: 8pt, fill: pbs-muted, tracking: 1pt, upper[Reference Period])\
          #text(size: 10pt, fill: pbs-text, weight: "bold",
            font: ("Georgia", "Times New Roman"), [July – February 2025–26])
        ],
      )
    ]

    #rect(width: 100%, height: 2pt,
      fill: gradient.linear(pbs-green, pbs-gold, pbs-green, angle: 0deg))

    // ── TOC (optional) ────────────────────────────────────
    #if toc {
      block(width: 100%, fill: pbs-cream,
        inset: (x: 0.75in, top: 18pt, bottom: 14pt),
      )[
        #block(width: 100%, stroke: (left: 4pt + pbs-green),
          fill: rgb("#eef4ed"),
          inset: (left: 16pt, right: 12pt, top: 10pt, bottom: 10pt),
          radius: (right: 3pt),
        )[
          #text(size: 10pt, weight: "bold", fill: pbs-green,
            font: ("Georgia", "Times New Roman"),
            tracking: 1pt, upper[Table of Contents])
          #v(6pt)
          #outline(title: none, depth: toc_depth, indent: toc_indent)
        ]
      ]
    }

    // ── Report highlights ─────────────────────────────────
    // FIX: replaced v(1fr) with a fixed gap so the vast blank
    // area between the meta strip and the cards disappears.
    #v(2em)
    #block(width: 100%, fill: pbs-cream,
      inset: (x: 0.75in, top: 20pt, bottom: 24pt),
    )[
      #text(size: 9pt, weight: "bold", fill: pbs-green,
        font: ("Georgia", "Times New Roman"),
        tracking: 1.5pt, upper[Report Highlights])
      #v(10pt)
      #grid(
        columns: (1fr, 1fr, 1fr),
        column-gutter: 14pt,

        block(
          width: 100%,
          stroke: (top: 3pt + pbs-green, bottom: 0.6pt + rgb("#d4d0c4"),
                   left: 0.6pt + rgb("#d4d0c4"), right: 0.6pt + rgb("#d4d0c4")),
          fill: pbs-gold-pale,
          inset: (x: 10pt, top: 10pt, bottom: 12pt),
          radius: (bottom: 3pt),
        )[
          #text(size: 7.5pt, fill: pbs-muted, tracking: 1pt,
            font: ("Georgia", "Times New Roman"), upper[Exports])
          #v(6pt)
          #text(size: 16pt, weight: "bold", fill: pbs-green,
            font: ("Georgia", "Times New Roman"),
            [#sym.dollar 2,278 mn])
          #v(4pt)
          #text(size: 8pt, fill: dec-red,
            font: ("Georgia", "Times New Roman"), [▼ 25.43% vs Jan 2026])
        ],

        block(
          width: 100%,
          stroke: (top: 3pt + imp-dark, bottom: 0.6pt + rgb("#d4d0c4"),
                   left: 0.6pt + rgb("#d4d0c4"), right: 0.6pt + rgb("#d4d0c4")),
          fill: pbs-gold-pale,
          inset: (x: 10pt, top: 10pt, bottom: 12pt),
          radius: (bottom: 3pt),
        )[
          #text(size: 7.5pt, fill: pbs-muted, tracking: 1pt,
            font: ("Georgia", "Times New Roman"), upper[Imports])
          #v(6pt)
          #text(size: 16pt, weight: "bold", fill: imp-dark,
            font: ("Georgia", "Times New Roman"),
            [#sym.dollar 5,318 mn])
          #v(4pt)
          #text(size: 8pt, fill: dec-red,
            font: ("Georgia", "Times New Roman"), [▼ 8.39% vs Jan 2026])
        ],

        block(
          width: 100%,
          stroke: (top: 3pt + bot-dark, bottom: 0.6pt + rgb("#d4d0c4"),
                   left: 0.6pt + rgb("#d4d0c4"), right: 0.6pt + rgb("#d4d0c4")),
          fill: pbs-gold-pale,
          inset: (x: 10pt, top: 10pt, bottom: 12pt),
          radius: (bottom: 3pt),
        )[
          #text(size: 7.5pt, fill: pbs-muted, tracking: 1pt,
            font: ("Georgia", "Times New Roman"), upper[Trade Deficit])
          #v(6pt)
          #text(size: 16pt, weight: "bold", fill: dec-red,
            font: ("Georgia", "Times New Roman"),
            [(−) #sym.dollar 3,040 mn])
          #v(4pt)
          #text(size: 8pt, fill: pbs-muted,
            font: ("Georgia", "Times New Roman"), [February 2026])
        ],
      )
    ]

    // ── Cover footer ──────────────────────────────────────
    #place(bottom)[
      #rect(width: 100%, height: 22pt, fill: pbs-green,
        inset: (x: 0.75in, y: 5pt),
      )[
        #grid(
          columns: (2fr, 1fr),
          align(left)[
            #text(size: 8pt, fill: white, font: ("Georgia", "Times New Roman"),
              [Pakistan Bureau of Statistics | Government of Pakistan | www.pbs.gov.pk])
          ],
          align(right)[
            #text(size: 8pt, fill: white, font: ("Georgia", "Times New Roman"),
              [March 2026])
          ],
        )
      ]
    ]
  ]

  // ══════════════════════════════════════════════════════════
  // BODY
  // ══════════════════════════════════════════════════════════
  set page(fill: pbs-cream)

  doc
}
