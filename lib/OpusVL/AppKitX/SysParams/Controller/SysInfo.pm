package OpusVL::AppKitX::SysParams::Controller::SysInfo;

use strict;
use Moose;
use namespace::autoclean;
use OpusVL::SysParams;
use Try::Tiny;


BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; }
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_name          => 'System Parameters',
    appkit_icon          => '/static/images/config-small.png',
    appkit_myclass       => 'OpusVL::AppKitX::SysParams',  
    appkit_shared_module => 'Configuration',
    appkit_method_group  => 'Configuration',
	path                 => 'adm/sysinfo',
);

sub auto 
    : Action
    : AppKitFeature('System Parameters')
{
	my $self = shift;
	my $c    = shift;

	$c->stash->{section}      = 'System Parameters';
    push @{$c->stash->{breadcrumbs}},
	{
        name => 'System Parameters',
        url  => $c->uri_for ($self->action_for ('list_params'))
    };
    my $schema = $c->model('SysParams')->schema;
    $c->stash->{sys_params} = OpusVL::SysParams->new({ schema => $schema });

	$c->stash->{urls} =
	{
		sys_info_list => sub { $c->uri_for ( $self->action_for ('list_params')      ) },
		sys_info_set  => sub { $c->uri_for ( $self->action_for ('set_param'), shift ) },
		sys_info_set_json  => sub { $c->uri_for ( $self->action_for ('set_json_param'), shift ) },
		sys_info_del  => sub { $c->uri_for ( $self->action_for ('del_param'), shift ) },
		sys_info_new  => sub { $c->uri_for ( $self->action_for ('new_param') ) },
	};
}

# FIXME: do we really want this to be Navigation Home?  I kind of suspect
# we either want to give this app a less generic name or allow it to be merged
# with other modules, in which case this navigation home could be a pain.
sub list_params
	: Path
	: NavigationName('System Parameters')
    : AppKitFeature('System Parameters')
{
	my $self = shift;
	my $c    = shift;
	
	$c->stash->{sys_info} = $c->model ('SysParams::SysInfo')->search_rs;
}

sub set_param
	: Path('set')
	: Args(1)
	: AppKitForm
    : AppKitFeature('System Parameters')
{
	my $self  = shift;
	my $c     = shift;
	my $param = shift;
	my $form  = $c->stash->{form};
	my $value = $c->model ('SysParams::SysInfo')->get ($param);

	my $return_url = $c->stash->{urls}{sys_info_list}->();

	$form->default_values
	({
		name  => $param,
		value => $value
	});

	if ($c->req->param ('cancelbutton'))
	{
		$c->flash->{status_msg} = 'System Parameter not Changed';
		$c->res->redirect ($return_url);
		$c->detach;
	}

	if ($form->submitted_and_valid)
	{
		$c->model ('SysParams::SysInfo')->set ($param => $form->param_value ('value'));
		$c->flash->{status_msg} = 'System Parameter Successfully Altered';
		$c->res->redirect ($return_url);
		$c->detach;
	}
}

sub set_json_param
	: Path('set_json')
	: Args(1)
	: AppKitForm('modules/sysinfo/set_param.yml')
    : AppKitFeature('System Parameters')
{
	my $self  = shift;
	my $c     = shift;
	my $param = shift;
	my $form  = $c->stash->{form};
	my $value = $c->stash->{sys_params}->get_json ($param);

	my $return_url = $c->stash->{urls}{sys_info_list}->();

	$form->default_values
	({
		name  => $param,
		value => $value
	});

	if ($c->req->param ('cancelbutton'))
	{
		$c->flash->{status_msg} = 'System Parameter not Changed';
		$c->res->redirect ($return_url);
		$c->detach;
	}

	if ($form->submitted_and_valid)
	{
        my $success = 0;
        try
        {
            $c->stash->{sys_params}->set_json ($param => $form->param_value ('value'));
            $c->flash->{status_msg} = 'System Parameter Successfully Altered';
            $success = 1;
        }
        catch
        {
            $c->log->debug(__PACKAGE__ . '->set_json_param exception: ' . $_);
            $form->get_field('value')->get_constraint({ type => 'Callback' })->force_errors(1);
            $form->process;
        };
        if($success)
        {
            $c->res->redirect ($return_url);
            $c->detach;
        }
	}
}

sub del_param
	: Path('del')
	: Args(1)
	: AppKitForm(delete.yml)
    : AppKitFeature('System Parameters')
{
	my $self  = shift;
	my $c     = shift;
	my $param = shift;
	my $form  = $c->stash->{form};
	my $value = $c->model ('SysParams::SysInfo')->get ($param);

	my $return_url = $c->stash->{urls}{sys_info_list}->();

	if ($c->req->param ('cancel'))
	{
		$c->flash->{status_msg} = 'System Parameter Not Deleted';
		$c->res->redirect ($return_url);
		$c->detach;
	}

	if ($form->submitted_and_valid)
	{
		$c->model ('SysParams::SysInfo')->del ($param);
		$c->flash->{status_msg} = 'System Parameter Successfully Deleted';
		$c->res->redirect ($return_url);
		$c->detach;
	}
    else
    {
        $c->stash->{param_value} = $value;
        $c->stash->{param_name}  = $param;
    }
}

sub new_param
	: Path('new')
	: Args(0)
	: AppKitForm
    : AppKitFeature('System Parameters')
{
	my $self  = shift;
	my $c     = shift;
	my $form  = $c->stash->{form};
	
	my $return_url = $c->stash->{urls}{sys_info_list}->();

	if ($c->req->param ('cancelbutton'))
	{
		$c->flash->{status_msg} = 'System Parameter Not Set';
		$c->res->redirect ($return_url);
		$c->detach;
	}

	if ($form->submitted_and_valid)
	{
		my $name  = $form->param_value ('name');
		my $value = $form->param_value ('value');
		$c->model ('SysParams::SysInfo')->set ($name => $value);
		$c->flash->{status_msg} = 'System Parameter Successfully Created';
		$c->res->redirect ($return_url);
		$c->detach;
	}
}

1;

