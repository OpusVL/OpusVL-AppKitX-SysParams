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

$mech->submit_form(
    with_fields => {
        name => 'test',
        value => 'validation',
        data_type => 'text',
    },
    button => 'submitbutton');
$mech->content_like(qr'System Parameter Successfully Created'i);
$mech->content_like(qr'validation'i, 'Check value is visible');

$mech->follow_link_ok ({text_regex => qr/Edit/, url_regex => qr/test$/}, 'Lets edit the setting');
$mech->submit_form(
    with_fields => {
        value => 'altered',
    },
    button => 'submitbutton');

$mech->follow_link_ok ({text_regex => qr/Edit/, url_regex => qr/test$/}, 'Lets edit the setting');
my $form = $mech->form_with_fields(qw/value data_type/);
$mech->post($form->action, {
    name => 'test',
    value => [qw/test array items/],
    data_type => 'array',
    submitbutton => 'submitbutton'
});
$mech->content_like(qr'<ul>\s*<li>\s*test'i, 'Check value is visible');
# lets try to add it again to prove we can't.
$mech->follow_link_ok ({text_regex => qr/Create a parameter/i, url_regex => qr/new$/}, 'Lets add a setting');
$mech->submit_form(
    with_fields => {
        name => 'test',
        value => 'validation',
        data_type => 'text',
    },
    button => 'submitbutton');
$mech->content_like(qr'already exists'i);
open my $fh, ">", "mech.html";
print $fh $mech->content;
$mech->submit_form(
    with_fields => {
        name => 'bad.value',
        value => 'validation',
    },
    button => 'cancelbutton');

$mech->follow_link_ok ({text_regex => qr/Delete/, url_regex => qr/test$/}, 'Lets delete the setting');
$mech->content_like(qr'sure'i);
# FIXME it currently doesn't show non-text values on this page
$mech->submit_form(with_fields => {confirm => 'Yes'}, button => 'confirm');
$mech->content_like(qr'Successfully Deleted'i);

done_testing;
