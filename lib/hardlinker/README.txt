hardlinker
	by Roger Jungemann (MIT License)
	http://github.com/thefifthcircuit/hardlinker
	
A library for blog software, to allow users to link to other articles and
media using a simple shorthand inspired by Everything2.com "hardlinks".

Further inspiration was found in the wiki example code of _why's Camping
framework.

Usage:

	require 'hardlinker'
	include TFCWiki

	h = Hardlinker.new
	h.linkers += [
		Linkers::Image.new, Linkers::SWF.new, Linkers::OGV.new,
	  Linkers::FLV.new, Linkers::MP4.new, Linkers::MP3.new, Linkers::Default.new
	]
	  
	puts h.render "An example of [[hardlinked|hardlinked text]]."
	  #=> "An example of <a href="/hardlinked?name=hardlinked">hardlinked text</a>."
	
More linkers can be added, to extend the functionality. Just append an object
that responds to a "call" method to the linkers array. Each linker is checked
in order to see whether it will convert a given link. See the "linkers"
directory for more information.

To Do:

	html pages--open in facebox
	add width/height tags to images, click to open full-size in facebox
	subtitles for ogv and flv