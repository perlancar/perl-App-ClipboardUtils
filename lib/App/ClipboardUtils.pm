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
    description => <<'MARKDOWN',

Note that if you supply a regex, you should not have any capture groups in the
regex.

MARKDOWN
    cmdline_aliases => {s=>{}},
};
$SPEC{add_clipboard_content}{args}{tee} = {
    summary => 'Pass stdin to stdout',
    schema => ['true*'],
    description => <<'MARKDOWN',

MARKDOWN
    cmdline_aliases => {t=>{}},
};
sub add_clipboard_content {
    my %args = @_;
    my $split_by = delete $args{split_by};
    my $tee = delete $args{tee};

    if (defined $split_by) {
        my $content = delete $args{content};
        my @split_parts = split /($split_by)/, $content;
        log_trace "split_by=%s, split_contents=%s", $split_by, \@split_parts;

        my $res = [204, "OK (no content)"];
        my $i = 0;
        while (my ($part, $separator) = splice @split_parts, 0, 2) {
            if ($tee) {
                print $part;
                print $separator if defined $separator;
            }

            # do not add empty part to clipboard
            if (length $part) {
                $res = Clipboard::Any::add_clipboard_content(
                    %args, content => $part,
                ); # currently we use the last add_clipboard_content status
            }
        }
        $res->[3]{'func.parts'} = @split_parts;
        $res;
    } else {
        print $args{content} if $tee;
        Clipboard::Any::add_clipboard_content(%args);
    }
}

$SPEC{tee_clipboard_content} = clone $Clipboard::Any::SPEC{add_clipboard_content};
$SPEC{tee_clipboard_content}{summary} = 'Shortcut for add-clipboard-content --tee';
$SPEC{tee_clipboard_content}{description} = '';
delete $SPEC{tee_clipboard_content}{args}{tee};
sub tee_clipboard_content {
    add_clipboard_content(@_, tee => 1);
}

1;
# ABSTRACT: CLI utilities related to clipboard

=head1 DESCRIPTION

This distribution contains the following CLI utilities related to clipboard:

# INSERT_EXECS_LIST
