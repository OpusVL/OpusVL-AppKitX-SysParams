#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/AppKit TestApp/i, 'see if it has our text');

$mech->content_like(qr/Access denied/i, 'check not logged in');
$mech->submit_form(form_number => 1,
    fields => {
        username => 'appkitadmin',
        password => 'password',
        remember => 'remember',
    },
);
$mech->content_like(qr/Welcome to AppKit TestApp/i, 'Check login good');

$mech->get_ok('/adm/sysinfo');
$mech->content_like(qr'System Parameters'i);
$mech->follow_link_ok ({text_regex => qr/Create a parameter/i, url_regex => qr/new$/}, 'Lets add a setting');

$mech->submit_form(form_number => 1,
    fields => {
        name => 'test',
        value => 'validation',
    },
    button => 'submitbutton');
$mech->content_like(qr'Must be of format 'i);
$mech->submit_form(form_number => 1,
    fields => {
        name => 'test.value',
        value => 'validation',
    },
    button => 'submitbutton');
$mech->content_like(qr'System Parameter Successfully Created'i);

$mech->follow_link_ok ({text_regex => qr/Edit Setting/, url_regex => qr/test\.value$/}, 'Lets edit the setting');
$mech->submit_form(form_number => 1,
    fields => {
        name => 'test.value',
        value => 'altered',
    },
    button => 'submitbutton');

$mech->follow_link_ok ({text_regex => qr/Edit JSON/, url_regex => qr/test\.value$/}, 'Lets edit the setting');
$mech->submit_form(form_number => 1,
    fields => {
        name => 'test.value',
        value => '[ 1, 2, 3]',
    },
    button => 'submitbutton');

# lets try to add it again to prove we can't.
$mech->follow_link_ok ({text_regex => qr/Delete/, url_regex => qr/test\.value$/}, 'Lets delete the setting');
$mech->content_like(qr'sure'i);
$mech->submit_form(form_number => 1, fields => {}, button => 'confirm');
$mech->content_like(qr'Successfully Deleted'i);

done_testing;
