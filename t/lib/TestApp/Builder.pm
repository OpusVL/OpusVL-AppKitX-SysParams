package TestApp::Builder;

use Moose;
extends 'OpusVL::AppKit::Builder';

override _build_superclasses => sub
{
  return [ 'OpusVL::AppKit' ]
};

override _build_plugins => sub {
    my $plugins = super(); # Get what CatalystX::AppBuilder gives you

    push @$plugins, qw(
        +OpusVL::AppKitX::SysParams
    );

    return $plugins;
};

override _build_config => sub {
    my $self   = shift;
    my $config = super(); # Get what CatalystX::AppBuilder gives you

    # point the AppKitAuth Model to the correct DB file....
    $config->{'Model::AppKitAuthDB'} = 
    {
        schema_class => 'OpusVL::AppKit::Schema::AppKitAuthDB',
        connect_info => [
          'dbi:SQLite:' . TestApp->path_to('root','appkit-auth.db'),
        ],
    };

    $config->{'Model::SysParams'} = 
    {
        connect_info => [
          'dbi:SQLite:' . TestApp->path_to('root','test_params.db'),
        ],
    };

    # .. add static dir into the config for Static::Simple..
    my $static_dirs = $config->{"Plugin::Static::Simple"}->{include_path};
    unshift(@$static_dirs, TestApp->path_to('root'));
    $config->{"Plugin::Static::Simple"}->{include_path} = $static_dirs;
    
    # .. allow access regardless of ACL rules...
    $config->{'appkit_can_access_actionpaths'} = ['custom/custom'];

    $config->{application_style} = 1;

    # DEBUGIN!!!!
    #$config->{'appkit_can_access_everything'} = 1;
    
    $config->{application_name} = 'AppKit TestApp';
    $config->{default_view}     = 'AppKitTT';
    
    return $config;
};

1;
