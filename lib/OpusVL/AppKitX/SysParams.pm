package OpusVL::AppKitX::SysParams;
use Moose::Role;
use CatalystX::InjectComponent;
use File::ShareDir qw/module_dir/;
use namespace::autoclean;

our $VERSION = '0.06';

after 'setup_components' => sub {
    my $class = shift;
   
    my $tt_view       = $class->config->{default_view} || 'TT';
    my $template_path = module_dir('OpusVL::AppKitX::SysParams') . 
                        '/root/templates';
    unless ($class->view($tt_view)->include_path ~~ $template_path) {
        push @{$class->view($tt_view)->include_path}, $template_path;
    }
   
    # .. add static dir into the config for Static::Simple..
    my $static_dirs = $class->config->{static}->{include_path};
    unshift(@$static_dirs, File::Spec->rel2abs(module_dir(__PACKAGE__) . '/root' ));
    $class->config->{static}->{include_path} = $static_dirs;
    
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

OpusVL::AppKitX::SysParams - 

=head1 DESCRIPTION

UI Module for setting the SysParams.

=head1 METHODS

=head1 BUGS

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

Copyright 2011 Opus Vision Limited, All Rights Reserved.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

