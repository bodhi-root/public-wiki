---
title: Analytics in Excel
---

> "Excel is like heroin for analysts.  They just can't stop using it." - Jason Perkins, British Telecom

## Overview

It's just about impossible to do any kind of analytics without being proficient in Excel.  Excel will let you quickly view, sort, summarize, and chart data.  It will be assumed that people on this page have at least an intermediate mastery of Excel.  Content will focus on more advanced tips and techniques that may not be as widely known.

## Basic Data Organization

Inspiration: __Data organization in spreadsheets.  The American Statistician.  2017.__

The article above provides a good overview of best practices for data organization.  The main points are:

### 1. Be Consistent

Try to use the same names and value types both within and across spreadsheets.  Whether you use "STO_NO" or "StoreNumber" be consistent.

### 2. Choose Good Names for Things

Be descriptive.  Avoid spaces in names.  These make it harder to import and work with data in other environments (like R).

| Good Name        | Good Alternative   | Avoid            |
|------------------|--------------------|------------------|
| Max_temp_C       | MaxTemp            | Maximum Temp (C) |
| Precipitation_mm | Precipitation      | precmm           |
| Mean_year_growth | MeanYearGrowth     | Mean growth/year |
| sex	             | sex                | M/F              |
| weight           | weight	            | w.               |
| cell_type        | CellType           | Cell type        |
| Observation_01   | first_observation  | 1st Obs.         |

### 3. Make It Rectangular

The first row should contain variable names.  This means the first piece of data should be in cell A2.  (You'd be surprised how many times this rule has been broken!)

### 4. Create a Data Dictionary

A separate sheet that describes what each column contains is helpful.  Try to provide: column name, display name (if different), units, and a description

### 5. Put Just one thing in a cell

Don't try to combine things like x- and y-coordinates into one cell.  Split them up.

### 6. No Calculations in the raw data files

Keep your raw data simple (CSV-like even).  Pull it into one tab that way and don't touch it.  Then you can do calculations and visualizations in other tabs.

### 7. Don't use font color or highlighting as data

This is helpful for presentation, but the coloring should be based on an actual value in a cell somewhere.  Example: if you want to mark rows as "good", create a column named "good", set to the value to TRUE, and then conditionally format the row based on the value of that cell.

### 8. No empty cells

This one is controversial. But there may be a different between an empty cell and a value like "NA" (not available).  If you need to create this difference use something like "NA" for missing values.

### 9. Save the data in plain text files

If you've followed these rules, you should be able to export your data to CSV and easily import it into other tools like R or Python.  When you do so, it is encouraged to format dates using the ISO standard: "yyyy-mm-dd".
