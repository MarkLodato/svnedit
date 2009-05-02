#!/usr/bin/env perl

# Copyright (c) 2009 Mark Lodato
# See license at bottom of file.

use warnings;
use strict;

my $BUFSIZ = 4096 * 1024;

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

