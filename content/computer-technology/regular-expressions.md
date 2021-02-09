---
title: Regular Expression Cheat Sheet
---

This morning I had to program some regular expressions.  As usual, I found myself Googling for some help. I used to have a nice cheat sheet for regular expressions, but I appear to have lost it. Let's create another one.

## Examples

| Name | Pattern | Description |
|------|---------|-------------|
| Integer | ```\d+``` | Match a sequence of digits (must have at least 1) |
| Real Number | ```\d*(.\d*)?``` | Allows numbers before and after the decimal point (cannot end with a decimal though) |
| Hexadecimal | ```[0-9a-f]+``` | Hexdecimal digits (0-9 or a-f) |
| Date        | ```\d{4}-\d{2}-\d{2}``` | Date in "yyyy-mm-dd" format |

## Character Expressions

| Characters   | Descriptions |
|--------------|--------------|
| ```[abc]```  | Find one character from the options between the brackets |
| ```[^abc]``` | Find one character NOT between the brackets |
| ```[0-9]```  | Find one character in the range 0 to 9 |

## Character Shortcuts

| Shortcut | Equivalent | Description |
|----------|------------|-------------|
| ```.```  | ```[^\n]``` | Any character (except a line break) |
| ```\d``` | ```[0-9]``` | Digit (0-9) |
| ```\s``` | ```[ \t\n\r\v]``` | Whitespace (space, tab, newline, carriage return, vertical tab) |
| ```\w``` | ```[a-zA-Z0-9_]``` | "Word" character (typically: ascii letter, digit, or underscore) |

## Escaped Characters

Use "\\" to escape the following special characters: ```.*+?$^/[{()}]\```

## Groups

| Group        | Description | Example | Example Match |
|--------------|-------------|---------|---------------|
| ```\|```      | "OR": match one of the terms |	```22\|33\|44``` | ```33``` |
| ```(...)```  | Capturing group.  This can be used to return a specific part of the text or to reference it later | ```A(nt\|pple)``` | ```Apple``` (capturing "pple") |
| ```(?...)``` | Non-capturing group.	| ```A(?:nt\|pple)``` | ```Apple``` (nothing captured) |
| ```\1```     | Contents of group 1	| ```r(\w)g\1x``` | ```regex``` |
| ```\2```     | Contents of group 2	| ```(\d\d)\+(\d\d)=\2\+\1``` | ```12+65=65+12``` |

## Repetitions

| Symbol      | Description        |
|-------------|--------------------|
| ```?```     | Once or none       |
| ```*```     | Zero or more times |
| ```+```     | One or more times  |
| ```{3}```   | Exactly 3 times    |
| ```{2,4}``` | 2-4 times          |
| ```{3,}```  | 3 or more times    |

## Anchors and Boundaries

| Symbol  | Description   |
|---------|---------------|
| ```^``` | Start of text |
| ```$``` | End of text   |

## References

* [Java Regular Expressions (w3schools)](https://www.w3schools.com/java/java_regex.asp)
* [Regeg Cheat Sheet (very detailed)](https://www.rexegg.com/regex-quickstart.html)
