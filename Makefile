#!/usr/bin/make -f

BLOG := $(MAKE) -f $(lastword $(MAKEFILE_LIST)) --no-print-directory
ifneq ($(filter-out help,$(MAKECMDGOALS)),)
-include config
endif

# Following can be configured in config
BLOG_TITLE ?= My blog
BLOG_ABOUT_TITLE ?= About
BLOG_DESC ?= This is my blog.
BLOG_KEYWORDS ?= blog, mblog
BLOG_LANG ?= en
BLOG_AUTHOR ?= Author
BLOG_DATE_FORMAT ?= %Y-%m-%d %r
BLOG_INDEX_DATE_FORMAT ?= %Y-%m-%d
BLOG_URL_ROOT ?= http://localhost/
BLOG_REMOTE ?= /var/www/blog
BLOG_FEED_MAX ?= 20
BLOG_FEEDS ?= rss atom

.PHONY: help init build deploy clean

ARTICLES = $(shell git ls-tree HEAD --name-only -- articles/*.md 2>/dev/null)

help:
	$(info make init|build|deploy)

init:
	mkdir -p articles static static/css static/media templates
	printf '<!DOCTYPE html>\n<html lang="$(BLOG_LANG)">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n<title>$$TITLE</title>\n<meta name="author" content="$$AUTHOR">\n<meta name="description" content="$$DESC">\n<meta name="keywords" content="$(BLOG_KEYWORDS)">\n<link rel="icon" href="$$FAVICON" type="image/x-icon"/>\n<link rel="apple-touch-icon" type="image/x-icon" href="$$FAVICON">\n<link rel="canonical" href="$(BLOG_URL_ROOT)"/>\n<meta http-equiv="X-UA-Compatible" content="IE=edge">\n<meta name="apple-mobile-web-app-capable" content="yes">\n<meta name="mobile-web-app-capable" content="yes">\n<meta property="og:image" content="$$FAVICON"/>\n<meta property="og:url" content="$(BLOG_URL_ROOT)"/>\n<meta property="og:site_name" content="$(BLOG_TITLE)"/><link rel="stylesheet" href="$$STYLESHEET" type="text/css"/>\n</head>\n<body>\n' > templates/header.html
	printf '</body>\n</html>' > templates/footer.html
	printf '<main>' > templates/index_header.html
	printf '<h2>Articles</h2>\n<ul id=article-list>' > templates/article_list_header.html
	printf '<li>$$DATE - <a href="$$URL">$$TITLE</a></li>' > templates/article_entry.html
	printf '' > templates/article_separator.html
	printf '</ul>' > templates/article_list_footer.html
	printf '</main>\n<footer>\n</footer>' > templates/index_footer.html
	printf '<main>' > templates/article_header.html
	printf '</main>\n<footer>\n<hr>\n<p><i>Posted on: $$DATE_POSTED, last updated on: $$DATE_EDITED, written by: $$AUTHOR</i></p></footer>' > templates/article_footer.html
	printf '' > index.md
	printf '' > about.md
	printf '' > static/css/style.css
	printf '<main>' > templates/about_header.html
	printf '</main>\n<footer>\n</footer>' > templates/about_footer.html
	printf 'build\n' > .git/info/exclude
	printf 'build\nrss.xml\natom.xml' > .gitignore

build: build/index.html build/about.html $(patsubst articles/%.md,build/blog/%.html,$(ARTICLES)) $(patsubst %,build/%.xml,$(BLOG_FEEDS)) build/robots.txt build/sitemap.xml

deploy: build
		rsync -rLtvz build/ static/ $(BLOG_REMOTE)

clean:
	rm -rf build

build/index.html: index.md $(ARTICLES) $(addprefix templates/,$(addsuffix .html,header index_header article_list_header article_entry article_separator article_list_footer index_footer footer))
	mkdir -p build build/blog
	TITLE="$(BLOG_TITLE)"; \
	AUTHOR="$(BLOG_AUTHOR)"; \
	DESC="$(BLOG_DESC)"; \
	STYLESHEET="./css/style.css"; \
	FAVICON="./media/favicon.ico"; \
	export TITLE; \
	export AUTHOR; \
	export DESC; \
	export STYLESHEET; \
	export FAVICON; \
	envsubst < templates/header.html > $@; \
	envsubst < templates/index_header.html >> $@; \
	envsubst < templates/article_list_header.html >> $@; \
	first=true; \
	echo $(ARTICLES); \
	for f in $(ARTICLES); do \
		printf '%s ' "$$f"; \
		git log -n 1 --diff-filter=A --date="format:%s $(BLOG_INDEX_DATE_FORMAT)" --pretty=format:'%ad%n' -- "$$f"; \
	done | sort -k2nr | cut -d" " -f1,3- | while IFS=" " read -r FILE DATE; do \
		"$$first" || envsubst < templates/article_separator.html; \
		URL="`printf '%s' "\$$FILE" | sed 's,^articles/\(.*\).md,blog\/\1,'`.html" \
		DATE="$$DATE" \
		TITLE="`head -n1 "\$$FILE" | sed -e 's/^# //g'`" \
		envsubst < templates/article_entry.html; \
		first=false; \
	done >> $@; \
	envsubst < templates/article_list_footer.html >> $@; \
	markdown < index.md >> $@; \
	envsubst < templates/index_footer.html >> $@; \
	envsubst < templates/footer.html >> $@; \

build/about.html: about.md $(addprefix templates/,$(addsuffix .html,header about_header about_footer footer))
	mkdir -p build
	TITLE="$(BLOG_ABOUT_TITLE)"; \
	AUTHOR="$(BLOG_AUTHOR)"; \
	DESC="$(BLOG_DESC)"; \
	STYLESHEET="./css/style.css"; \
	FAVICON="./media/favicon.ico"; \
	export TITLE; \
	export AUTHOR; \
	export DESC; \
	export STYLESHEET; \
	export FAVICON; \
	envsubst < templates/header.html > $@; \
	envsubst < templates/about_header.html >> $@; \
	markdown < about.md >> $@; \
	envsubst < templates/about_footer.html >> $@; \
	envsubst < templates/footer.html >> $@; \

build/blog/%.html: articles/%.md $(addprefix templates/,$(addsuffix .html,header article_header article_footer footer))
	mkdir -p build build/blog
	TITLE="$(shell head -n1 $< | sed 's/^# \+//')"; \
	AUTHOR="$(shell git log --format="%an" -- "$<" | tail -n 1)"; \
	DESC="$(BLOG_DESC)"; \
	STYLESHEET="../css/style.css"; \
	FAVICON="../media/favicon.ico"; \
	export TITLE; \
	export AUTHOR; \
	export DESC; \
	export STYLESHEET; \
	export FAVICON; \
	DATE_POSTED="$(shell git log -n 1 --diff-filter=A --date="format:$(BLOG_DATE_FORMAT)" --pretty=format:'%ad' -- "$<")"; \
	export DATE_POSTED; \
	DATE_EDITED="$(shell git log -n 1 --date="format:$(BLOG_DATE_FORMAT)" --pretty=format:'%ad' -- "$<")"; \
	export DATE_EDITED; \
	envsubst < templates/header.html > $@; \
	envsubst < templates/article_header.html >> $@; \
	sed -e '/^;/d' < $< | markdown >> $@; \
	envsubst < templates/article_footer.html >> $@; \
	envsubst < templates/footer.html >> $@; \

build/rss.xml: $(ARTICLES)
	printf '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0">\n<channel>\n<title>%s</title>\n<link>%s</link>\n<description>%s</description>\n' \
		"$(BLOG_TITLE)" "$(BLOG_URL_ROOT)" "$(BLOG_DESC)" > $@
	for f in $(ARTICLES); do \
		printf '%s ' "$$f"; \
		git log -n 1 --diff-filter=A --date="format:%s %a, %d %b %Y %H:%M:%S %z" --pretty=format:'%ad%n' -- "$$f"; \
	done | sort -k2nr | head -n $(BLOG_FEED_MAX) | cut -d" " -f1,3- | while IFS=" " read -r FILE DATE; do \
		printf '<item>\n<title>%s</title>\n<link>%s</link>\n<guid>%s</guid>\n<pubDate>%s</pubDate>\n<description><![CDATA[%s]]></description>\n</item>\n' \
			"`head -n 1 $$FILE | sed 's/^# //'`" \
			"$(BLOG_URL_ROOT)blog/`basename $$FILE | sed 's/\.md/\.html/'`" \
			"$(BLOG_URL_ROOT)blog/`basename $$FILE | sed 's/\.md/\.html/'`" \
			"$$DATE" \
			"`markdown < $$FILE`"; \
	done >> $@
	printf '</channel>\n</rss>\n' >> $@

build/atom.xml: $(ARTICLES)
	printf '<?xml version="1.0" encoding="UTF-8"?>\n<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">\n<title type="text">%s</title>\n<subtitle type="text">%s</subtitle>\n<updated>%s</updated>\n<link rel="alternate" type="text/html" href="%s"/>\n<id>%s</id>\n<link rel="self" type="application/atom+xml" href="%s"/>\n' \
		"$(BLOG_TITLE)" "$(BLOG_DESC)" "$(shell date +%Y-%m-%dT%H:%M:%SZ)" "$(BLOG_URL_ROOT)" "$(BLOG_URL_ROOT)atom.xml" "$(BLOG_URL_ROOT)atom.xml" > $@
	for f in $(ARTICLES); do \
		printf '%s ' "$$f"; \
		git log -n 1 --diff-filter=A --date="format:%s %Y-%m-%dT%H:%M:%SZ" --pretty=format:'%ad %aN%n' -- "$$f"; \
	done | sort -k2nr | head -n $(BLOG_FEED_MAX) | cut -d" " -f1,3- | while IFS=" " read -r FILE DATE AUTHOR; do \
		printf '<entry>\n<title type="text">%s</title>\n<link rel="alternate" type="text/html" href="%s"/>\n<id>%s</id>\n<published>%s</published>\n<updated>%s</updated>\n<author><name>%s</name></author>\n<summary type="html"><![CDATA[%s]]></summary>\n</entry>\n' \
			"`head -n 1 $$FILE | sed 's/^# //'`" \
			"$(BLOG_URL_ROOT)blog/`basename $$FILE | sed 's/\.md/\.html/'`" \
			"$(BLOG_URL_ROOT)blog/`basename $$FILE | sed 's/\.md/\.html/'`" \
			"$$DATE" \
			"`git log -n 1 --date="format:%Y-%m-%dT%H:%M:%SZ" --pretty=format:'%ad' -- "$$FILE"`" \
			"$$AUTHOR" \
			"`markdown < $$FILE`"; \
	done >> $@
	printf '</feed>\n' >> $@

build/robots.txt:
	printf "User-agent: *\n" > $@
	printf "Allow: *\n" >> $@
	printf "Sitemap: $(BLOG_URL_ROOT)sitemap.xml" >> $@

build/sitemap.xml:
	printf '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' > $@
	printf '<url><loc>$(BLOG_URL_ROOT)index.html</loc></url>\n' >> $@
	printf '<url><loc>$(BLOG_URL_ROOT)about.html</loc></url>\n' >> $@
	for f in $(ARTICLES); do \
		printf "<url><loc>$(BLOG_URL_ROOT)blog/`basename $$f | sed 's/\.md/\.html/'`</loc></url>\n"; \
	done >> $@
	printf '</urlset>' >> $@
