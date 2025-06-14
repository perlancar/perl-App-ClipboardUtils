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

{
    $SPEC{add_clipboard_content} = clone $Clipboard::Any::SPEC{add_clipboard_content};

    # because we also have --command and do our own while(<>) { ... }
    delete $SPEC{add_clipboard_content}{args}{content}{cmdline_src};

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

    $SPEC{add_clipboard_content}{args}{command_line} = {
        summary => 'For every line of input in *stdin*, execute a command, feed it the input line, and add the output to clipboard',
        schema => ['str*'],
        description => <<'MARKDOWN',

Note that when you use this option, the `--content` argument is ignored. Input
is taken from stdin. With `--tee`, each output will be printed to stdout. After
eof, the utility will return empty result.

An example for using this option:

    % clipadd -c safer
    Foo Bar, Co., Ltd.
    foo-bar-co-ltd
    BaZZ, Co., Ltd.
    bazz-co-ltd
    _

MARKDOWN
        cmdline_aliases => {c=>{}},
    };
}

sub add_clipboard_content {
    my %args = @_;
    my $split_by = delete $args{split_by};
    my $tee = delete $args{tee};
    my $command_line = $args{command_line};

    if (defined $command_line) {

        require IPC::System::Options;

        while (defined(my $input_line = <>)) {
            my $stdout;
            IPC::System::Options::run({log=>1, die=>1, stdin => $input_line, capture_stdout => \$stdout}, $command_line);

            if (defined $split_by) {
                my $content = delete $args{content};
                my @split_parts = split /($split_by)/, $content;
                log_trace "split_by=%s, split_contents=%s", $split_by, \@split_parts;

                my $i = 0;
                while (my ($part, $separator) = splice @split_parts, 0, 2) {
                    if ($tee) {
                        print $part;
                        print $separator if defined $separator;
                    }

                    # do not add empty part to clipboard
                    if (length $part) {
                        my $res = Clipboard::Any::add_clipboard_content(
                            %args, content => $part,
                        );
                        return $res unless $res->[0] == 200;
                    }
                }
            } else {
                print $stdout if $tee;
                my $res = Clipboard::Any::add_clipboard_content(%args, content => $stdout);
                return $res unless $res->[0] == 200;
            }
        } # while input
        return [200, "OK"];

    } else {

        my $content = $args{content};
        $content = do { local $/; scalar <> } unless defined $content;
        $args{content} = $content;

        if (defined $split_by) {
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
            print $content if $tee;
            Clipboard::Any::add_clipboard_content(%args);
        }

    } # if command_line
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
