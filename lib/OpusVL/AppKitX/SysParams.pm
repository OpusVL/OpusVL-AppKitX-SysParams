package OpusVL::AppKitX::SysParams;
use Moose::Role;
use CatalystX::InjectComponent;
use File::ShareDir qw/module_dir/;
use namespace::autoclean;
use experimental 'smartmatch';

our $VERSION = '0.30';

after 'setup_components' => sub {
    my $class = shift;
   
    my $tt_view       = $class->config->{default_view} || 'TT';
    my $template_path = module_dir('OpusVL::AppKitX::SysParams') . 
                        '/root/templates';
    unless ($class->view($tt_view)->include_path ~~ $template_path) {
        push @{$class->view($tt_view)->include_path}, $template_path;
    }
   
    # .. add static dir into the config for Static::Simple..
    my $static_dirs = $class->config->{"Plugin::Static::Simple"}->{include_path};
    unshift(@$static_dirs, File::Spec->rel2abs(module_dir(__PACKAGE__) . '/root' ));
    $class->config->{"Plugin::Static::Simple"}->{include_path} = $static_dirs;
    
    # .. inject your components here ..
    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'OpusVL::AppKitX::SysParams::Controller::SysInfo',
        as        => 'Controller::Modules::SysInfo'
    );

    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'OpusVL::AppKitX::SysParams::Model::SysParams',
        as        => 'Model::SysParams'
    );
};

1;

=head1 NAME

OpusVL::AppKitX::SysParams - UI for SysParams.

=head1 DESCRIPTION

UI Module for setting the SysParams.

=head1 METHODS

=head1 BUGS

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

Copyright 2011 Opus Vision Limited.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

If you require assistance, support, or further development of this software, please contact OpusVL using the details below:

=over 4

=item *

Telephone: +44 (0)1788 298 410

=item *

Email: community@opusvl.com

=item *

Web: L<http://opusvl.com>

=back

=cut

