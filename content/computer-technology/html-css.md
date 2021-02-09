---
title: HTML and CSS
---

It's been a few decades since I first learned HTML and CSS.  A lot has changed in that time.  I recently found myself wanting to catch up on some of the modern best practices for web development.  I found this cool online book:

* [Interneting is Hard: HTML and CSS](https://www.internetingishard.com/html-and-css/)

This provided some good code snippets and I wanted to document here.

## Page Struture

```
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8"/>
    <title>Page Title</title>
    <link rel="stylesheet" href="css/main.css"/>
  </head>
  <body>
    ...
  </body>
</html>
```

## CSS

### Resetting Styles

The following CSS removes the default margin and padding that the browser uses for all elements.  It also sets the "box-sizing" method to "border-box" so that when you say an element is 300 pixels wide, you can be sure that it actually is.  The book recommends doing this for all websites you build and says that almost all modern CSS style sheets start with this.

```
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}
```
