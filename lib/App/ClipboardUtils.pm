package App::ClipboardUtils;

use strict;
use warnings;
use Log::ger;

# AUTHORITY
# DATE
# DIST
# VERSION

use Clipboard::Any ();
use Clone::PP qw(clone);

our %SPEC;

$SPEC{add_clipboard_content} = clone $Clipboard::Any::SPEC{add_clipboard_content};
$SPEC{add_clipboard_content}{args}{split_by} = {
    summary => 'Split content by specified string/regex, add the split content as multiple clipboard entries',
    schema => ['str_or_re*'],
};
sub add_clipboard_content {
    my %args = @_;
    my $split_by = delete $args{split_by};

    if (defined $split_by) {
        my $content = delete $args{content};
        my @split_contents = split $split_by, $content;
        log_trace "split_by=%s, split_contents=%s", $split_by, \@split_contents;

        my $res = [204, "OK (no content)"];
        for my $part (@split_contents) {
            $res = Clipboard::Any::add_clipboard_content(
                %args, content => $part,
            ); # currently we use the last add_clipboard_content status
        }
        $res->[3]{'func.parts'} = @split_contents;
        $res;
    } else {
        Clipboard::Any::add_clipboard_content(%args);
    }
}

1;
# ABSTRACT: CLI utilities related to clipboard

=head1 DESCRIPTION

This distribution contains the following CLI utilities related to clipboard:

# INSERT_EXECS_LIST
