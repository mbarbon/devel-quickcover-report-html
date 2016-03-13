#!/usr/bin/env perl

use strict;
use warnings;

use Devel::QuickCover::Report;
use Devel::QuickCover::Report::Html;

my $report = Devel::QuickCover::Report->new;
my $html_report = Devel::QuickCover::Report::Html->new(
    directory   => 'report',
);

$report->load('qc.dat');
$html_report->add_report($report);

$html_report->render;

exit 0;

