all : README.rst

README.rst : svn_edit_authors.pl
	pod2html --noindex $^ | pandoc -f html -t rst | sed -e '/^-\+$$/d' > $@
	$(RM) pod2htmd.tmp pod2htmi.tmp
