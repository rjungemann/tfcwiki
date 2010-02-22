tfcwiki
    by Roger Jungemann
    http://thefifthcircuit.com/

== DESCRIPTION:

tfcwiki is a hybrid blog/wiki. Pages can be published to the news feed or not (the latter is more like a wiki page).

You can link to other pages using one of the following:

[[name_of_page_in_slug_form|Here's the label for the page!]]
[[another_name_of_page]]

You can link to images as well by doing this:

[[Image Name.jpg]]
[[Image Name.jpg|Here's some alternative text]]

tfcwiki also has a built-in uploader. Uploaded files can be referenced like above or by using traditional links.

== FEATURES/PROBLEMS:

* I need to replace /:name/show with /:name
* I want to add Everything2 (http://everything2.org) styled "softlinks" using Rack::Flash.
* Add authentication using turnstile
* Finish RSS support
* Finish audio, movie, and swf support.

== SYNOPSIS:

To get started, type in "rackup config.ru -p4567" to start the server. Then navigate to http://localhost:4567/ in your browser.

See the attached config.ru file for the simplest example.

== REQUIREMENTS:

* sinatra, moneta, rack-flash

== INSTALL:

    git clone git://github.com/thefifthcircuit/s3_uploader.git
 