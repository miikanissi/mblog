#!/usr/bin/make -f
export LC_ALL=C

BLOG := $(MAKE) -f $(lastword $(MAKEFILE_LIST)) --no-print-directory
ifneq ($(filter-out help,$(MAKECMDGOALS)),)
-include config
endif

# Following can be configured in config
SITE_NAME ?= My Blog
TITLE ?= My Blog
ABOUT_TITLE ?= About
DESCRIPTION ?= This is my blog.
KEYWORDS ?= blog, mblog
LANG ?= en
AUTHOR ?= Author
AUTHOR_EMAIL ?= author@email.com
DATE_FORMAT ?= %Y-%m-%d %r
INDEX_DATE_FORMAT ?= %Y-%m-%d
BASE_URL ?= http://localhost
REMOTE ?= /var/www/blog
FEED_MAX ?= 20
GITHUB ?= https://github.com

.PHONY: help init build deploy clean

ARTICLES = $(shell git ls-tree HEAD --name-only -- articles/*.md 2>/dev/null)

help:
	$(info make init|build|deploy)

init:
	mkdir -p articles static static/css static/media templates
	printf '<!DOCTYPE html>\n<html lang="$$LANG">\n<head>\n<meta charset="utf-8" />\n<meta name="viewport" content="width=device-width, initial-scale=1" />\n<title>$$TITLE</title>\n<meta name="author" content="$$AUTHOR" />\n<meta name="description" content="$$DESCRIPTION" />\n<meta name="keywords" content="$$KEYWORDS" />\n<link rel="icon" href="$$FAVICON" type="image/x-icon" />\n<link rel="apple-touch-icon" type="image/x-icon" href="$$FAVICON" />\n<link rel="canonical" href="$$BASE_URL" />\n<meta http-equiv="X-UA-Compatible" content="IE=edge" />\n<meta name="apple-mobile-web-app-capable" content="yes" />\n<meta name="mobile-web-app-capable" content="yes" />\n<meta property="og:image" content="$$FAVICON" />\n<meta property="og:url" content="$$BASE_URL" />\n<meta property="og:site_name" content="$$SITE_NAME" />\n<link rel="stylesheet" href="$$STYLESHEET" type="text/css" />\n<link rel="alternate" type="application/rss+xml" href="$$RSS" title="$$SITE_NAME" />\n</head>\n<body>\n<header>\n<h1 class="main-title">$$AUTHOR <em>($$BASE_URL)</em></h1>\n<hr />\n<nav>\n<ul>\n<li><a href="$$INDEX">Home</a></li>\n<li><a href="$$ABOUT">About</a></li>\n<li><a href="$$GITHUB">GitHub</a></li>\n<li><a href="$$RSS">RSS</a></li>\n</ul>\n</nav>\n</header>\n<main>$$CONTENT</main>\n<footer>\n<hr />\n$$POST_DATE By $$AUTHOR (<a href="mailto:$$AUTHOR_EMAIL">$$AUTHOR_EMAIL</a>).\n<br />\nBuilt with <a href="https://github.com/miikanissi/mblog/">mblog</a>.\n</footer>\n</body>\n</html>' > templates/website_layout.html
	printf '$$INDEX_TOP_CONTENT $$BLOG_LIST $$INDEX_BOTTOM_CONTENT' > templates/index_content.html
	printf '$$ABOUT_CONTENT' > templates/about_content.html
	printf '<h2>Blog Posts</h2>\n<ul id="article-list">\n$$BLOG_ITEMS\n</ul>\n<pre class="example">$$RSS</pre>' > templates/article_list.html
	printf '<li>$$DATE - <a href="$$URL">$$TITLE</a></li>' > templates/article_entry.html
	printf 'Posted on: $$DATE_POSTED, last updated on: $$DATE_EDITED<br />' > templates/post_date.html
	printf '' > templates/article_separator.html
	printf '' > index-top.md
	printf '' > index-bottom.md
	printf '' > about.md
	printf '' > static/css/style.css
	printf 'build\n' > .git/info/exclude
	printf 'build' > .gitignore

build: build/index.html build/about.html $(patsubst articles/%.md,build/blog/%.html,$(ARTICLES)) build/rss.xml build/robots.txt build/sitemap.xml

deploy: build
		rsync -rLtvz build/ static/ $(REMOTE)

clean:
	rm -rf build

build/index.html: index-top.md index-bottom.md $(ARTICLES) $(addprefix templates/,$(addsuffix .html,website_layout article_list article_entry article_separator index_content))
	mkdir -p build build/blog
	export TITLE="$(TITLE)"; \
	export AUTHOR="$(AUTHOR)"; \
	export AUTHOR_EMAIL="$(AUTHOR_EMAIL)"; \
	export GITHUB="$(GITHUB)"; \
	export DESCRIPTION="$(DESCRIPTION)"; \
	export KEYWORDS="$(KEYWORDS)"; \
	export LANG="$(LANG)"; \
	export BASE_URL="$(BASE_URL)"; \
	export STYLESHEET="./css/style.css"; \
	export FAVICON="./media/favicon.ico"; \
	export INDEX="./index.html"; \
	export ABOUT="./about.html"; \
	export RSS="$(BASE_URL)/rss.xml"; \
	export SITE_NAME="$(SITE_NAME)"; \
	first=true; \
	echo $(ARTICLES); \
	for f in $(ARTICLES); do \
		printf '%s ' "$$f"; \
		git log -n 1 --diff-filter=A --date="format:%s $(INDEX_DATE_FORMAT)" --pretty=format:'%ad%n' -- "$$f"; \
	done | sort -k2nr | cut -d" " -f1,3- | while IFS=" " read -r FILE DATE; do \
		"$$first" || envsubst < templates/article_separator.html; \
		URL="`printf '%s' "\$$FILE" | sed 's,^articles/\(.*\).md,blog\/\1,'`.html" \
		DATE="$$DATE" \
		TITLE="`head -n1 "\$$FILE" | sed -e 's/^# //g'`" \
		envsubst < templates/article_entry.html; \
		first=false; \
	done > temp-blog-items.html; \
	BLOG_ITEMS=`cat temp-blog-items.html`; \
	rm temp-blog-items.html; \
	export BLOG_ITEMS; \
	envsubst < templates/article_list.html > temp-blog-list.html; \
	BLOG_LIST=`cat temp-blog-list.html`; \
	rm temp-blog-list.html; \
	export BLOG_LIST; \
	markdown < index-top.md > temp-index-top.html; \
	INDEX_TOP_CONTENT=`cat temp-index-top.html`; \
	rm temp-index-top.html; \
	export INDEX_TOP_CONTENT; \
	markdown < index-bottom.md > temp-index-bottom.html; \
	INDEX_BOTTOM_CONTENT=`cat temp-index-bottom.html`; \
	rm temp-index-bottom.html; \
	export INDEX_BOTTOM_CONTENT; \
	envsubst < templates/index_content.html > temp-index-content.html; \
	CONTENT=`cat temp-index-content.html`; \
	rm temp-index-content.html; \
	export CONTENT; \
	envsubst < templates/website_layout.html > $@; \

build/about.html: about.md $(addprefix templates/,$(addsuffix .html,website_layout about_content))
	mkdir -p build
	export TITLE="$(ABOUT_TITLE)"; \
	export AUTHOR="$(AUTHOR)"; \
	export AUTHOR_EMAIL="$(AUTHOR_EMAIL)"; \
	export GITHUB="$(GITHUB)"; \
	export DESCRIPTION="$(DESCRIPTION)"; \
	export KEYWORDS="$(KEYWORDS)"; \
	export LANG="$(LANG)"; \
	export BASE_URL="$(BASE_URL)"; \
	export STYLESHEET="./css/style.css"; \
	export FAVICON="./media/favicon.ico"; \
	export INDEX="./index.html"; \
	export ABOUT="./about.html"; \
	export RSS="$(BASE_URL)/rss.xml"; \
	export SITE_NAME="$(SITE_NAME)"; \
	markdown < about.md > temp-about.html; \
	ABOUT_CONTENT=`cat temp-about.html`; \
	rm temp-about.html; \
	export ABOUT_CONTENT; \
	envsubst < templates/about_content.html > temp-about-page.html; \
	CONTENT=`cat temp-about-page.html`; \
	rm temp-about-page.html; \
	export CONTENT; \
	envsubst < templates/website_layout.html > $@; \

build/blog/%.html: articles/%.md $(addprefix templates/,$(addsuffix .html,website_layout post_date))
	mkdir -p build build/blog
	export TITLE="$(shell head -n1 $< | sed 's/^# \+//')"; \
	export AUTHOR="$(shell git log --format="%an" -- "$<" | tail -n 1)"; \
	export AUTHOR_EMAIL="$(shell git log --format="%ae" -- "$<" | tail -n 1)"; \
	export GITHUB="$(GITHUB)"; \
	export DESCRIPTION="$(DESCRIPTION)"; \
	export KEYWORDS="$(KEYWORDS)"; \
	export LANG="$(LANG)"; \
	export BASE_URL="$(BASE_URL)"; \
	export STYLESHEET="../css/style.css"; \
	export FAVICON="../media/favicon.ico"; \
	export INDEX="../index.html"; \
	export ABOUT="../about.html"; \
	export RSS="$(BASE_URL)/rss.xml"; \
	export SITE_NAME="$(SITE_NAME)"; \
	export DATE_POSTED="$(shell git log -n 1 --diff-filter=A --date="format:$(DATE_FORMAT)" --pretty=format:'%ad' -- "$<")"; \
	export DATE_EDITED="$(shell git log -n 1 --date="format:$(DATE_FORMAT)" --pretty=format:'%ad' -- "$<")"; \
	envsubst < templates/post_date.html > temp-post-date.html; \
	POST_DATE=`cat temp-post-date.html`; \
	rm temp-post-date.html; \
	export POST_DATE; \
	sed -e '/^;/d' < $< | markdown > temp-article.html; \
	CONTENT=`cat temp-article.html`; \
	rm temp-article.html; \
	export CONTENT; \
	envsubst < templates/website_layout.html > $@; \

build/rss.xml: $(ARTICLES)
	printf '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0">\n<channel>\n<title>%s</title>\n<link>%s</link>\n<description>%s</description>\n' \
		"$(TITLE)" "$(BASE_URL)" "$(DESCRIPTION)" > $@
	for f in $(ARTICLES); do \
		printf '%s ' "$$f"; \
		git log -n 1 --diff-filter=A --date="format:%s %a, %d %b %Y %H:%M:%S %z" --pretty=format:'%ad%n' -- "$$f"; \
	done | sort -k2nr | head -n $(FEED_MAX) | cut -d" " -f1,3- | while IFS=" " read -r FILE DATE; do \
		printf '<item>\n<title>%s</title>\n<link>%s</link>\n<guid>%s</guid>\n<pubDate>%s</pubDate>\n<description><![CDATA[%s]]></description>\n</item>\n' \
			"`head -n 1 $$FILE | sed 's/^# //'`" \
			"$(BASE_URL)/blog/`basename $$FILE | sed 's/\.md/\.html/'`" \
			"$(BASE_URL)/blog/`basename $$FILE | sed 's/\.md/\.html/'`" \
			"$$DATE" \
			"`markdown < $$FILE`"; \
	done >> $@
	printf '</channel>\n</rss>\n' >> $@

build/robots.txt:
	printf "User-agent: *\n" > $@
	printf "Allow: *\n" >> $@
	printf "Sitemap: $(BASE_URL)/sitemap.xml" >> $@

build/sitemap.xml:
	printf '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' > $@
	printf '<url><loc>$(BASE_URL)/</loc><lastmod>%s</lastmod></url>\n' \
		"`git log -n 1 --date="format:%Y-%m-%dT%H:%M:%SZ" --pretty=format:'%ad' -- "index.md"`"	>> $@
	printf '<url><loc>$(BASE_URL)/about</loc><lastmod>%s</lastmod></url>\n' \
		"`git log -n 1 --date="format:%Y-%m-%dT%H:%M:%SZ" --pretty=format:'%ad' -- "about.md"`"	>> $@
	for f in $(ARTICLES); do \
		printf "<url><loc>$(BASE_URL)/blog/`basename $$f | sed 's/\.[^.]*$$//'`</loc><lastmod>%s</lastmod></url>\n" \
			"`git log -n 1 --date="format:%Y-%m-%dT%H:%M:%SZ" --pretty=format:'%ad' -- "$$f"`"; \
	done >> $@
	printf '</urlset>' >> $@
