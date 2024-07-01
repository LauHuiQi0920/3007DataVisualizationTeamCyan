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
    // Check for empty string by comparing directly to an empty string
    v.trim() == ""
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


#let poster(
  // The poster's size.
  size: "'36x24' or '48x36''",

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "Department Name",

  // University logo.
  univ_logo: "Logo Path",

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
  footer_text: "Footer Text",

  // Any URL, like a link to the conference website.
  footer_url: "Footer URL",

  // Email IDs of the authors.
  footer_email_ids: "Email IDs (separated by commas)",

  // Color of the footer.
  footer_color: "Hex Color Code",
  
  // Text color of the footer.
  footer_text_color: "Hex Color Code",

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3",

  // University logo's scale (in %).
  univ_logo_scale: "45",

  // University logo's column size (in in).
  univ_logo_column_size: "10",

  // Title and authors' column size (in in).
  title_column_size: "25",

  // Poster title's font size (in pt).
  title_font_size: "48",

  // Authors' font size (in pt).
  authors_font_size: "36",

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "30",

  // Footer's text font size (in pt).
  footer_text_font_size: "40",

  // The poster's content.
  body
) = {
  // Set the body font.
  set text(font: "Arial", size: 15pt)
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  // This poster defaults to 36in x 24in.
  set page(
    width: width,
    height: height,
    fill: rgb(249, 249, 249),
    margin: 
      (top: 1in,bottom: 2in, left: 1.5in, right: 1.5in),
    footer: [
      #set align(center)
      #set text(32pt, white)
      #block(
        fill: rgb(170, 55, 52),
        width: 100%,
        inset: 20pt,
        [
          //#text(font: "Courier", size: footer_url_font_size, footer_url) 
          //#h(1fr) 
          #text(size: footer_text_font_size, smallcaps(footer_text)) 
          #h(1fr) 
          #text(font: "Courier", size: footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Configure headings.
  //set heading(numbering: "I.A.1.")
  show heading: it => locate(loc => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).at(loc)
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(24pt, weight: 400)
    if it.level == 1 [
      // First-level headings are centered smallcaps.
      #set align(left)
      #set text(28pt)
      #set text(weight: 700)
      #set text (fill: rgb(170, 55, 52))
      #show: smallcaps
      #v(50pt, weak: true)
      #if it.numbering != none {
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(30pt, weak: true)
    ] else if it.level == 2 [
      // Second-level headings are run-ins.
      #set text(style: "normal")
      #set text(20pt)
      #set text(weight: 700)
      #v(32pt, weak: true)
      #if it.numbering != none {
        numbering("i.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(10pt, weak: true)
    ] else [
      // Third level headings are run-ins too, but different.
      #if it.level == 3 {
        numbering("1)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  })

  // Arranging the logo, title, authors, and department in the header.
  align(left,
    grid(
      rows: 2,
      columns: (title_column_size, univ_logo_column_size),
      column-gutter: 40pt,
      row-gutter: 25pt,
       block(
        fill: rgb(170, 55, 52),
        inset: 25pt,
        width: 100%,
        text(fill: rgb(255, 255, 255), title_font_size, title + "\n\n") + 
        text(fill: rgb(255, 255, 255), authors_font_size, strong(text(fill: rgb(171, 255, 255), authors)) + 
            "   (" + departments + ") ")
      ),
      image(univ_logo, width: univ_logo_scale),
    )
  )

  // Start three column mode and configure paragraph properties.
  show: columns.with(num_columns, gutter: 64pt)
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the keywords.
  if keywords != () [
      #set text(24pt, weight: 400)
      #show "Keywords": smallcaps
      *Keywords* --- #keywords.join(", ")
  ]

  // Display the poster's contents.
  body
}
// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates


#show: doc => poster(
   title: [#strong[Mapping Crime in the Los Angeles: A Visual Journey (2020-2024)];], 
  // TODO: use Quarto's normalized metadata.
   authors: [Team Cyan], 
   departments: [Information and Communication Technologies], 
   size: "33x23", 

  // Institution logo.
   univ_logo: "./imgs/sit-logo.png", 

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [Information Visualization 2024], 

  // Any URL, like a link to the conference website.
  

  // Emails of the authors.
   footer_email_ids: [singaporetech.edu.sg], 

  // Color of the footer.
  footer_color: rgb(205,5,5),
  
  
  // Text color of the footer.
  

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  

  // Number of columns in the poster.
  

  // University logo's scale (in %).
  

  // University logo's column size (in in).
  

  // Title and authors' column size (in in).
  

  // Poster title's font size (in pt).
  

  // Authors' font size (in pt).
  

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)

#block(
  fill: rgb(243, 241, 241),
  inset: 30pt,
  width: 100%
)[
  = Introduction
<introduction>
Crime in America is a significant concern, impacting the safety and well-being of residents, businesses, and tourism. There has been a sharp rise in motor vehicle thefts, which increased by 25% from 2019 to 2022#footnote[#link("https://www.marketwatch.com/guides/insurance-services/car-theft-statistics/");] ,demonstrating the need for continued efforts to curb the crime rate.
#v(1em)
Understanding and identifying areas with high crime rates can significantly enhance law enforcement training and preparation. Data consistently shows that neighborhoods such as South Los Angeles remain prevalent with violent crime#footnote[#link("https://www.latimes.com/california/story/2023-10-12/violent-crime-is-down-fear-is-up-why-is-la-perceived-as-dangerous");];. Utilizing past statistical data and quantifiable information to identify hotspots allows law enforcement agencies to allocate resources more efficiently and maximize safety.
#v(1em)
Examining crime distribution in Los Angeles, a Medium visualization focuses on the University of Southern California’s University Park campus, using blue dots to represent crime incidents #footnote[#link("https://towardsdatascience.com/visualizing-crime-in-los-angeles-14db37572909/");] (@fig-wsj-on-poster). While straightforward, the plot could be refined for better clarity and impact.
]

#block(
  fill: white, // Set the background color
  inset: 30pt,
  width: 100%
)[
= Previous Visualization
#line(
  start: (0%, 0%),
  end: (100%, 0%),
  stroke: 3pt + rgb(170, 55, 52) 
)
<previous-visualization>
#block[
#block[
#figure([
#box(width: 100%,image("imgs/bad_graph.jpeg"))
], caption: figure.caption(
position: bottom, 
[
Crime distribution around USC, published by the Medium.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-wsj-on-poster>

]
]
]

#block(
  inset: 30pt,
  width: 100%
)[
= Strengths
<strengths>
+ Alpha was used on the circles allowing darker spots to appear if overlapped.

+ A gentle blue color was used, making it easy for users to identify crime-affected spots. The chosen color effectively contrasts with the map's background, enhancing visibility without clashing.

+ An area with good distribution was picked, as there are clusters displayed on the map.

+ As the mouse is hovered over the circles, the exact number of crimes is displayed through a tooltip \(@fig-infotip), allowing the user to see the exact number of crimes in that area .

#block[
#block[
#figure([
#box(width: 100%,image("imgs/combined.png"))
], caption: figure.caption(
position: bottom, 
[
Crime distribution around USC, published by the Medium.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-infotip>
]
]
]

#block(
  inset: 30pt,
  width: 100%
)[
= Suggested Improvements
<suggested-improvements>
+ #strong[State layer view:] separated with area code, performs better visualization of the crime distribution. A localize view does not represent a crime spread well for meaningful actions.

+ #strong[Identify type of crime clearly:] A clearer view of top crime should be labeled and display.

+ #strong[Add missing title and guides:] Title should be used for clear description

+ #strong[Add missing guides:] Guides should be used to show clear distinction of color shade to total crime count.

+ #strong[Use a saturation color palette:] Shows a meaningful progression through color space. Saturation palettes shows cold to hot zone allowing human to see intensity of an area.

+ #strong[Label locations:] Labeling popular city center allow enforcer to see crime distribution and easily identify the areas with high crime rate.

+ #strong[Add crime types for each area:] Displaying the top 3 crimes in each area allows for better understanding of the crime distribution and provides additional information.
]

#block(
  fill: rgb(243, 241, 241), // Set the background color
  inset: 30pt,
  width: 100%
)[
= Implementation
<implementation>
== Data
<data>
- The data used spans from January 1, 2020, to June 7, 2024, and is sourced from the universal crime data for Los Angeles#footnote[#link("https://data.lacity.org/Public-Safety/Crime-Data-from-2020-to-Present/2nrs-mtv8/data_preview");]. Unlike the subset of data ending in 2021 used in the previous visualization (@fig-wsj-on-poster), this dataset offers a more comprehensive view. Although there are datasets available for the years 2010 to 2019#footnote[#link("https://catalog.data.gov/dataset/crime-data-from-2010-to-2019");], they were not used due to differing formats.


== Software
<software>
We used the Quarto publication framework and the R programming language, along with the following third-party packages:

- #strong[#text(rgb(170, 55, 52))[dplyr]] for data manipulation
- #strong[#text(rgb(170, 55, 52))[tidyverse]] for data transformation, including #strong[#text(rgb(170, 55, 52))[ggplot2]] for visualization based on the grammar of graphics
- #strong[#text(rgb(170, 55, 52))[readxl]] for data import
- #strong[#text(rgb(170, 55, 52))[lubridate]] for date and time manipulation
- #strong[#text(rgb(170, 55, 52))[DT]] for interactive data tables
- #strong[#text(rgb(170, 55, 52))[knitr]] for dynamic document generation
- #strong[#text(rgb(170, 55, 52))[pals]] for qualitative color palettes
- #strong[#text(rgb(170, 55, 52))[RColorBrewer]] for sequential color palettes
]

#block(
  fill: white, // Set the background color
  inset: 30pt,
  width: 100%
)[
= Improved Visualization
#line(
  start: (0%, 0%),
  end: (100%, 0%),
  stroke: 3pt + rgb(170, 55, 52) 
)
<improved-visualization>
#block[
#block[
#figure([
#box(width: 100%,image("imgs/plot.png"))
], caption: figure.caption(
position: bottom, 
[
Top 3 crimes and total crimes by area.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)

]
]
]

#block(
  inset: 30pt,
  width: 100%
)[
= Further Suggestions for Interactivity
<further-suggestions-for-interactivity>
While our visualization was designed for a poster, interactive features were not implemented. However, in an HTML document, these features can be achieved using various R packages. #strong[#text(rgb(170, 55, 52))[ggplot2]] allows for #strong[hover, drag, zoom, and export];, which improves accessibility for people with sight disabilities by enabling zoom to increase text size. #strong[#text(rgb(170, 55, 52))[Shiny]] facilitates the #strong[sorting of graphs] to clearly differentiate categories and provides #strong[dynamic input];, such as displaying the distribution of only robbery crimes throughout the state. Additionally, #strong[#text(rgb(170, 55, 52))[plotly]] offers #strong[customized tooltips] with ggplot2, expands long town names, and shows exact numbers without crowding. By #strong[darkening borders] and adding shadows, plotly highlights areas when hovered, enhancing the overall user experience.
]

#block(
  fill: rgb(250,236,236), // Set the background color
  inset: 30pt,
  width: 100%
)[
= Conclusion
<conclusion>
The revised crime visualization for Los Angeles (2020-2024) improves on previous versions by adding area labels, a saturation color palette, and comprehensive guides. Highlighting the top three crime types per area provides deeper insights into local patterns. These enhancements make the visualization more complex yet user-friendly, aiding law enforcement in resource allocation and strategy development, and ultimately contributing to improved community safety.
]