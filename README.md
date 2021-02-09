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

## Changes from Original Template

The [original template](https://github.com/hasura/gatsby-gitbook-starter) had several things that I corrected right away.  Obviously, the branding needed to change so it didn't point to any hasura logos or links.  Next, I was surprised to see that there were very noticeable styling differences between the template and the [sample site](https://hasura.io/learn/graphql/react/introduction/) they use in demos.  The biggest changes I made to make the template look more like the demo site were:

* Removing the "light/dark" style slider, forcing dark theme for header and sidebar and light for content.
* Removing ugly "cyan" colors in highlighted and mouseover links and replacing with purple
* Fixing mobile menu view (removing ugly drop shadows and higlighting)

As I added content I also noticed a few other changes that I wanted to make:

* Left-aligning images
* Removing border-spacing and collapsing borders on tables
* Forcing all menu items closed and having exceptions for 'expandedNav' (rather than 'collapsedNav')
