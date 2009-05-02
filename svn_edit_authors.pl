#!/usr/bin/env perl

# Copyright (c) 2009 Mark Lodato
# See license at bottom of file.

=head1 NAME

svn_edit_authors.pl - filter the authors in an SVN dumpfile.

=head1 SYNOPSIS

svn_edit_authors.pl < svn.dump > svn-updated.dump

=head1 DESCRIPTION

This script filters the authors in a Subversion dumpfile through a custom
function.  To use this script, edit the `process_author' subroutine to modify
the authors as necessary.  As an example, to replace "Administrator" with
"admin", set:

    sub process_author {
        $_ = shift;
        s/^Administrator$/admin/;
        return $_;
    }

=head1 AUTHOR

Mark Lodato <mjlodat-at-gmail>

=head1 SEE ALSO

svnadmin(1)

=cut

use warnings;
use strict;

# Number of bytes to read at a time when processing each blob.
my $BUFSIZ = 4096 * 1024;

# Modify this function to process the usernames as needed.  The input argument
# will be the username; you must return the modified username.
sub process_author {
    $_ = shift;
    s/^Administrator$/admin/;
    return $_;
}


if (@ARGV != 0) {
    print STDERR "USAGE: $0 < svn.dump > svn-updated.dump\n";
    exit 1;
}


# First line must be the SVN dump header
$_ = <STDIN>;
if (not /^SVN-fs-dump-format-version:/) {
    die "unrecognized file format\n";
}
print;

# From now on, we only process revision nodes.
while (<STDIN>) {
    print;
    if (/^Revision-number: (\d+)$/) {
        # Read the header, extracting the property length and the
        # content-length.
        my $header = '';
        my $props;
        my ($proplen, $contentlen);
        while (<STDIN>) {
            $header .= $_;
            last if /^$/;
            $contentlen = $1 if /^Content-length: (\d+)$/;
            $proplen = $1 if /^Prop-content-length: (\d+)$/;
        }

        # Read the properties and update the svn:author.
        read STDIN, $props, $proplen;
        if ($props =~ /(?:\n|^)K \d+\n(?:svn:)?author\nV \d+\n(.*)\n/) {
            my $author = &process_author($1);
            if (defined $author) {
                my $len = length($author);
                $props =~ s/((?:\n|^)K \d+\n(?:svn:)?author\nV )\d+\n.*\n/$1$len\n$author\n/;
            }
        }

        # Update the lengths.
        if (length($props) != $proplen) {
            $contentlen += length($props) - $proplen;
            $proplen = length($props);
            $header =~ s/((?:\n|^)Prop-content-length: )\d+\n/$1$proplen\n/;
            $header =~ s/((?:\n|^)Content-length: )\d+\n/$1$contentlen\n/;
        }

        # Print the updated header and properties.
        print $header;
        print $props;

        # Read the rest of the content and print it.
        &read_content($contentlen - $proplen);
    }
    elsif (not /^$/) {
        # Non-revision: Read the content length then skip over the content.
        my $contentlen = 0;
        while (<STDIN>) {
            print;
            last if /^$/;
            $contentlen = $1 if /^Content-length: (\d+)$/;
        }
        &read_content($contentlen);
    }
}


sub read_content {
    my $contentlen = shift;
    my $buffer;
    my $bufsiz = $BUFSIZ;
    while ($contentlen > 0) {
        if ($bufsiz > $contentlen) {
            $bufsiz = $contentlen;
        }
        $contentlen -= read STDIN, $buffer, $bufsiz;
        print $buffer;
    }
}

__END__



Copyright (c) 2009 Mark Lodato

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

