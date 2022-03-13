# Mblog

A makefile based static blog website generator using basic UNIX tools. Write blogs in Markdown and publish as HTML. This tool creates an index page with a list of blog posts, an about page, an rss feed, a sitemap and a robots.txt file - all with the help of a makefile.

## Requirements

Mblog requires the following packages:

* coreutils
* sed
* markdown
* make
* git
* rsync (for deployment only)

## Installation / Configuration

Mblog can be customized to your liking by editing the source code, but for an easy startup do the following:

    mkdir mblog
    cd mblog && wget -L https://raw.githubusercontent.com/miikanissi/mblog/master/Makefile

To configure your own variables create a file called `config` and define the following with your own values:

    SITE_NAME:=Miika Nissi
    TITLE:=Miika Nissi
    ABOUT_TITLE:=About me - Miika Nissi
    DESCRIPTION:=This is my personal website: a place where you can read and learn about technology related subjects.
    KEYWORDS:=Miika Nissi, blog, resume, technology, programming
    LANG:=en
    AUTHOR:=Miika Nissi
    AUTHOR_EMAIL:=miika@miikanissi.com
    DATE_FORMAT:=%Y-%m-%d %r
    INDEX_DATE_FORMAT:=%Y-%m-%d
    BASE_URL:=https://miikanissi.com
    REMOTE:=/var/www/blog
    FEED_MAX:=20
    GITHUB:=https://github.com/miikanissi

### Variables

| Variable               | Description                                              |
| ---                    | ---                                                      |
| SITE_NAME              | Name of your site                                        |
| TITLE                  | Name and title of your blog                              |
| ABOUT_TITLE            | Name and title of your about page                        |
| DESCRIPTION            | Description of your website                              |
| KEYWORDS               | Keywords for your website for SEO                        |
| LANG                   | The main language used in your website                   |
| AUTHOR                 | The creator/author of the website                        |
| AUTHOR_EMAIL           | The email of the creator/author                          |
| DATE_FORMAT            | The date format of blog posts, check `man date` for help |
| INDEX_DATE_FORMAT      | The date format of blog posts for the index page         |
| BASE_URL               | The base URL of your website without a trailing          |
| REMOTE                 | The remote directory to deploy your website to           |
| FEED_MAX               | The maximum amount of blog posts on the rss/atom feed    |
| GITHUB                 | The Github link for menu                                 |

After you have created your personal config file you can run the following:

    git init
    make init
    echo '# Hello world' > articles/hello-world.md
    git add .
    git commit -m "Initial post"
    make build

This will initialize the file structure and create basic templates, to customize your blog you can write your own html/css for the templates. To write blog posts you write a markdown file inside the `articles/` directory and then you commit it into git. This way you will always have version control over your website and we can use git to get the creation and modification dates of posts. It is also possible to invite others to write posts for you by using pull requests on Git.

## Demo

I use mblog for my own personal website which you can check out [here](https://miikanissi.com/).
