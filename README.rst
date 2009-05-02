



NAME
====

svn\_edit\_authors.pl - filter the authors in an SVN dumpfile.




SYNOPSIS
========

svn\_edit\_authors.pl < svn.dump > svn-updated.dump




DESCRIPTION
===========

This script filters the authors in a Subversion dumpfile through a
custom function. To use this script, edit the ``process_author``
subroutine to modify the authors as necessary.



Example
-------

To replace "Administrator" with "admin", set:

::

        sub process_author {
            $_ = shift;
            s/^Administrator$/admin/;
            return $_;
        }




AUTHOR
======

Mark Lodato <lodatom-at-gmail>




SEE ALSO
========

``svnadmin(1)``


