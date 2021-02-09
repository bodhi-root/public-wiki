# Public Wiki

This is the second incarnation of my public wiki site.  Unlike the minimal design used earlier, this one uses Gatsby and the gatsby-gitbook-starter template to provide a sexy-looking site.  It even features "Edit on GitHub" links that allow you to edit pages directly on GitHub - which is pretty cool.

## Local Testing

You can run the development server locally with:

```
gastby develop
```

## Building and Pushing to Production

You can create a production build and test it with:

```
gatsby build --prefix-paths
gatsby serve --prefix-paths
```

If everything looks good you can push to production with:

```
TODO
```

## Handling a Website Prefix

The template seems to handle website prefixes very well.  The main change you have to make is in "config.js" where you specify:

```
gatsby: {
  pathPrefix: '/prefix/',
  ...
}
```

There is one link that breaks though, and that is the "home page" link attached to your site logo in the top left of the page.  Make sure you edit both the href link in your "title" HTML in the header config below.  Because you provide this HTML it is not automatically processed and prefixed by the web site.

```
header: {
  ...
  title:
    `<a href="/prefix/">Dan's Notes</a>`,
  ...
}
```

## Changes from Original Template

The [original template](https://github.com/hasura/gatsby-gitbook-starter) had several things that I corrected right away.  Obviously, the branding needed to change so it didn't point to any hasura logos or links.  Next, I was surprised to see that there were very noticeable styling differences between the template and the [sample site](https://hasura.io/learn/graphql/react/introduction/) they use in demos.  The biggest changes I made to make the template look more like the demo site were:

* Removing the "light/dark" style slider, forcing dark theme for header and sidebar and light for content.
* Removing ugly "cyan" colors in highlighted and mouseover links and replacing with purple
* Fixing mobile menu view (removing ugly drop shadows and higlighting)

As I added content I also noticed a few other changes that I wanted to make:

* Left-aligning images
* Removing border-spacing and collapsing borders on tables
* Forcing all menu items closed and having exceptions for 'expandedNav' (rather than 'collapsedNav')

## Notes on Creating Pages

### Frontmatter

All pages should have a "title" property in their frontmatter.  This is the title that will appear at the top of the page and the title that will appear in the navigation menus.  At least one page has to also have "metaTitle" and "metaDescription" (or else some queries break).  These properties are used in the HTML header of the page to set "<meta>" tag values.  I don't plan to use these, but since they are required I set them on one page: "index.md".

### Links

The site is setup to not use trailing slashes after pages.  This means if you have the following layout:

```
index.md
about.md
tech.md
tech/
  cool-article.md
```

You can link from "/index" to "/about" with ```[about]```.  If you want to link from "/index" to "/tech/cool-article" you do it with ```[tech/cool-article]```.  Use relative paths.  Don't include the ".md" file extension or a trailing slash.  (This ```trailingSlash: false``` setting is used intentionally so that the relative links used are valid both locally and when the website is built and deployed.)  When the site gets built it will create pages like:

```
index/index.html
about/index.html
tech/index.html
tech/cool-article/index.html
```

Don't worry about that though.  Even though a request to "/tech/cool-article/" is technically valid, you don't want to use it.  It will throw off the links to other pages.  A request to "/tech/cool-article" (no trailing slash) somehow knows how to add a slash, resolve the default page ("index.html") and then takes the slash away.  I don't know how it does this, but you can catch it adding and removin the slash in the browser URL if you are quick.

Links to other resources (images, documents, etc.) are handled automatically by the "gatsby-remark-copy-linked-files" plugin.  This will find all such links in your Markdown pages and copy them to unique locations in a "/static" folder.  Unlike my blog sites where I work hard to keep all the images with the blog post in the same folder - even upon deployment - I don't think it's as important for this type of website.  Everything "just works" and allows you to easily re-use images between pages if desired.
