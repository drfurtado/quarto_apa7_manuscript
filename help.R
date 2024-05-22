# commands
## update extension
quarto update wjschne/apaquarto

## New document
quarto use template wjschne/apaquarto

```{r}

#| label: apafg-importedgraphic

#| apa-cap: Figure caption

#| apa-note: This is a note below figure.

knitr::include_graphics("myfigure.png ")

# Markdown table

```{asis}
#| label: tbl-mytable2
#| tbl-cap: My Table
#| apa-twocolumn: true
#| apa-note: This is a note below the markdown table.
#| echo: true
#| ft.align: center

| Default | Left | Right | Center |
    |---------|:-----|------:|:------:|
    | 12      | 12   |    12 |   12   |
    | 123     | 123  |   123 |  123   |
    | 1       | 1    |     1 |   1    |
    ```
