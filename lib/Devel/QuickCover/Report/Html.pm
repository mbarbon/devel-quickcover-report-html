package Devel::QuickCover::Report::Html;

use strict;
use warnings;
use autodie qw(open close chdir);

use Devel::QuickCover::Report;
use File::Copy;
use File::ShareDir;
use File::Spec::Functions;
use IO::Compress::Gzip;
use POSIX;
use Text::MicroTemplate;

our $VERSION = '0.01';

my %TEMPLATES = (
    file      => _get_template('file.tmpl'),
    index     => _get_template('index.tmpl'),
    header    => _get_template('header.tmpl'),
);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        files       => [],
        directory   => $args{directory},
        compress    => $args{compress},
    }, $class;

    return $self;
}

sub add_report {
    my ($self, $report) = @_;
    my $files = $report->filenames;
    my $coverage = $report->coverage;

    for my $file (@$files) {
        $self->add_file(
            file_name   => $file,
            coverage    => $coverage->{$file},
        );
    }
}

sub add_file {
    my ($self, %args) = @_;
    my $item = $self->_make_item(\%args);

    push @{$self->{files}}, $item;
}

sub render {
    my ($self) = @_;
    my $date = POSIX::strftime('%c', localtime(time));
    my @existing;

    for my $item (@{$self->{files}}) {
        push @existing, $item if $self->_render_file($date, $item);
    }
    $self->render_main($date, \@existing);

    # copy CSS/JS
    File::Copy::copy(
        File::ShareDir::dist_file('Devel-QuickCover-Report-Html', 'quickcover.css'),
        File::Spec::Functions::catfile($self->{directory}, 'quickcover.css'));
    File::Copy::copy(
        File::ShareDir::dist_file('Devel-QuickCover-Report-Html', 'sorttable.js'),
        File::Spec::Functions::catfile($self->{directory}, 'sorttable.js'));
}

sub render_file {
    my ($self, %args) = @_;
    my $item = $self->_make_item(\%args);

    $self->_render_file($args{date}, $item);
}

sub render_main {
    my ($self, $date, $items) = @_;
    my @files = sort {
        $a->{display_name} cmp $b->{display_name}
    } @{$items || $self->{files}};

    $self->_write_template(
        $TEMPLATES{index},
        {
            date        => $date,
            files       => \@files,
            include     => \&_include,
            format_ratio=> \&_format_ratio,
            color_code  => \&_color_code,
        },
        $self->{directory},
        'index.html',
        $self->{compress},
    );
}

sub _make_item {
    my ($self, $args) = @_;
    my %item = (
        file_name       => $args->{file_name},
        display_name    => $args->{display_name} || $args->{file_name},
        coverage        => $args->{coverage},
        git_repository  => $args->{git_repository},
        git_commit      => $args->{git_commit},
        git_name        => $args->{git_name},
    );
    my $covered = grep $_, values %{$item{coverage}};
    $item{percentage} = $covered / keys %{$item{coverage}};
    ($item{report_name} = $item{file_name}) =~ s{\W}{-}g;
    $item{report_name} .= '.html';

    return \%item;
}

sub _render_file {
    my ($self, $date, $item) = @_;
    my $source = $self->_fetch_source($item);

    return unless $source;
    my $lines = ['I hope you never shee this...', split /\n/, $source];

    $self->_write_template(
        $TEMPLATES{file},
        {
            display_name    => $item->{display_name},
            coverage        => $item->{coverage},
            include         => \&_include,
            lines           => $lines,
            date            => $date,
        },
        $self->{directory},
        $item->{report_name},
        $self->{compress},
    );
}

sub _fetch_source {
    my ($self, $item) = @_;

    die "TODO" if $item->{git_repository};

    return unless -f $item->{file_name};
    open my $fh, '<', $item->{file_name};
    local $/;
    return scalar readline $fh;
}

sub _get_template {
    my ($basename) = @_;
    my $path = File::ShareDir::dist_file('Devel-QuickCover-Report-Html', $basename);
    my $tmpl = do {
        local $/;
        open my $fh, '<:utf8', $path or die "Unable to open '$path': $!";
        readline $fh;
    };

    return Text::MicroTemplate::build_mt($tmpl);
}

sub _write_template {
    my ($self, $sub, $data, $dir, $file, $compress) = @_;
    my $text = $sub->($data) . "";
    my $target = File::Spec::Functions::catfile($dir, $file);

    utf8::encode($text) if utf8::is_utf8($text);
    open my $fh, '>', $compress ? "$target.gz" : $target;
    if ($compress) {
        IO::Compress::Gzip::gzip(\$text, $fh)
              or die "gzip failed: $IO::Compress::Gzip::GzipError";
    } else {
        print $fh $text;
    }
    close $fh;
}

sub _include {
    $TEMPLATES{$_[0]}->($_[1]);
}

sub _format_ratio {
    my ($ratio) = @_;

    my $perc = $ratio * 100;
    if ($perc >= 0.01) {
        return sprintf '%.02f%%', $perc;
    } elsif ($perc >= 0.0001) {
        return sprintf '%.04f%%', $perc;
    } else {
        return '0';
    }
}

sub _color_code {
    my ($ratio) = @_;

    if ($ratio < .75) {
        return 'coverage-red';
    } elsif ($ratio < .90) {
        return 'coverage-orange';
    } elsif ($ratio < 1) {
        return 'coverage-yellow';
    } else {
        return 'coverage-green';
    }
}

1;

__END__

=head1 NAME

Devel::QuickCover::Report::Html - Simple Devel::QuickCover report generator

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the MIT License.

=cut
