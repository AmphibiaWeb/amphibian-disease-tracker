# Amphibian Disease Portal  - 
Find this gh-pages site here:

https://updates.amphibiandisease.org  

Categories:
 - News
 - Resources

## Additions
  - Drafts

## Reference links to writing:
 - [Jekyll][Jekyll]
 - [Markdown basics][Markdown]

# Centrarium [![Circle CI](https://circleci.com/gh/bencentra/centrarium/tree/master.svg?style=svg)](https://circleci.com/gh/bencentra/centrarium/tree/master)

Built with these awesome libraries: 
* [Bourbon][bourbon] 
* [Neat][neat]
* [Bitters][bitters]
* [Refills][refills]
* [Font Awesome][fontawesome]
* [HighlightJS][highlightjs]
* [Lightbox][lightbox]

Here's a [demo](http://bencentra.com/centrarium). It also works on [GitHub Pages](http://bencentra.github.io/centrarium/). I also use it for [my own website][bencentra].    

## Features

This theme comes with a number of features, including:
* Easily customizable fonts and colors
* Cover images for your homepage and blog posts
* Pagination enabled by default
* Archiving of posts by categories and tags
* Disqus integration for post comments
* Lightbox for viewing full-screen photos and albums
* Google Analytics with custom page name tracking
* Social media integration (Twitter, Facebook, LinkedIn, GitHub, and more)

## Updating Styles

If you want change the CSS of the theme, you'll probably want to check out these files in the `_sass/` directory:

* `base/_variables.scss`: Common values found throughout the project, including base font size, font families, colors, and more.
* `base/_typography.scss`: Base typography values for the site (see `typography.html` for a demonstration)
* `_layout.scss`: The primary styles for the layout and design of the theme. 

### Important Variables

Here are the important variables from `base/_variables.scss` you can tweak to customize the theme to your liking:

* `$base-font-family`: The font-family of the body text. Make sure to `@import` any new fonts!
* `$heading-font-family`: The font-family of the headers. Make sure to `@import` any new fonts!
* `$base-font-size`: The base font-size. Defaults to $em-base from Bourbon (`bourbon/settings/_px-to-em.scss`).
* `$base-font-color`: The color for the body text.
* `$action-color`: The color for links in the body text. 
* `$highlight-color`: The color for the footer and page headers (when no cover image provided).

## Configuration

All configuration options can be found in `_config.yml`. 

### Site Settings

* __title:__ The title for your site. Displayed in the navigation menu, the `index.html` header, and the footer.
* __subtitle:__ The subtitle of your site. Displayed in the `index.html` header.
* __email:__ Your email address, displayed with the Contact info in the footer.
* __name:__ Your name. _Currently unused._
* __description:__ The description of your site. Used for search engine results and displayed in the footer.
* __baseurl:__ The subpath of your site (e.g. /blog/).
* __url:__ The base hostname and protocol for your site.
* __cover:__ The relative path to your site's cover image.
* __logo:__ The relative path to your site's logo. Used in the navigation menu instead of the title if provided.

### Build Settings

* __markdown:__ Markdown parsing engine. Default is kramdown.
* __paginate:__ Number of posts to include on one page.
* __paginate_path:__ URL structure for pages.

### Archive Settings

Although this theme comes with a combined, categorized archive (see `posts.html`), you can enable further archive creation thanks to [jekyll-archives][archives]. Support for category and tag archive pages is included, but you can also add your own archive pages for years, months, and days.

To change archive settings, see the __jekyll-archives__ section of `_config.yml`:

```yml
jekyll-archives:
  enabled: 
    - categories
    - tags
  layout: 'archive'
  permalinks:
    category: '/category/:name/'
    tag: '/tag/:name/'
```

To fully disable the archive, remove the __jekyll-archives__ section AND remove it from the __gems__ list.

__NOTE:__ the Jekyll Archive gem is NOT included with GitHub pages! Disable the archive feature if you intend to deploy your site to GitHub pages.

A sitemap is also generated using [jekyll-sitemap][sitemap].

### Disqus Settings

You can enable [Disqus][disqus] comments for you site by including one config option:

* __disqus_shortname:__ Your Disqus username. If the property is set, Disqus comments will be included with your blog posts.

If you want to disable Disqus for only a specific page, add __disqus_disabled: true__ to the page's front matter.

### Google Analytics Settings

You can enable basic [Google Analytics][ga] pageview tracking by including your site's tracking ID:

* __ga_tracking_id__: The Tracking ID for your website. You can find it on your Google Analytics dashboard. If the property is set, Google Analytics will be added to the footer of each page.

### Social Settings

Your personal social network settings are combined with the social sharing options. In the __social__ seciton of `_config.yml`, include an entry for each network you want to include. For example:

```yml
social:
  - name: Twitter                         # Name of the service
    icon: twitter                         # Font Awesome icon to use (minus fa- prefix)
    username: TheBenCentra                # (User) Name to display in the footer link
    url: https://twitter.com/TheBenCentra # URL of your profile (leave blank to not display in footer)
    desc: Follow me on Twitter            # Description to display as link title, etc
    share: true                           # Include in the "Share" section of posts
```

### Social Protocols

Using the Open Graph Protocol or Twitter Card metadata, you can automatically set the images and text used when people share your site on Twitter or Facebook. These take a bit of setup, but are well worth it. The relevant fields are at the end of the `_config.yml` file.

Also there is another protocol, the Open Source protocol, for saying where your site is hosted if the source is open. This helps develops more easily see your code if they are interested, or if they have issues. For more, see http://osprotocol.com.

### Category Descriptions

You can enhance the `posts.html` archive page with descriptions of your post categories. See the __descriptions__ section of `_config.yml`:

```yml
# Category descriptions (for archive pages)
descriptions:
  - cat: jekyll
    desc: "Posts describing Jekyll setup techniques."
```

## License

MIT. See [LICENSE.MD](https://github.com/bencentra/centrarium/blob/master/LICENSE.md).

[bencentra]: http://bencentra.com
[bourbon]: http://bourbon.io/
[neat]: http://neat.bourbon.io/
[bitters]: http://bitters.bourbon.io/
[refills]: http://refills.bourbon.io/
[fontawesome]: http://fortawesome.github.io/Font-Awesome/
[highlightjs]: https://highlightjs.org/
[lightbox]: http://lokeshdhakar.com/projects/lightbox2/
[cover]: https://www.flickr.com/photos/79666107@N00/3796678503/in/photolist-6MuYfc-61Rtft-8XzPmY-a6Cozm-54eSMs-6oMJmk-aepZQq-9YkPHp-fiAEGE-dVP4Z5-oxPyJP-atKUFJ-9YHWA5-9YF2f2-9YF2gR-9YHVGN-9YHVvs-qZYYQ6-4JqP2i-a2peGy-9YHVUm-9YHVF7-9YHVCL-9YF3NK-cYteMo-aiPmb9-69dtAi-9YF21x-4aWpmn-7SLiUL-77pqVX-8vXbYv-4HGDSH-a2h5P1-8LsZrQ-9aj1ez-auPZ7q-9YHVMd-9YF2bi-9YF23D-8LpWpn-9an6KL-9YHVZL-dqZ3Cz-2GuvnX-9YHWUo-9YHVWd-p5Roh5-i1zTbv-6sYrUT
[disqus]: https://disqus.com/
[ga]: http://www.google.com/analytics/
[archives]: https://github.com/jekyll/jekyll-archives
[sitemap]: https://github.com/jekyll/jekyll-sitemap
[Jekyll]: https://jekyllrb.com/
[Markdown]: https://help.github.com/articles/markdown-basics/
