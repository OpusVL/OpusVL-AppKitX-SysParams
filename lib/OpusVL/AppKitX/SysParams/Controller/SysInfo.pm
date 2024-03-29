package OpusVL::AppKitX::SysParams::Controller::SysInfo;

use strict;
use Moose;
use namespace::autoclean;
use OpusVL::SysParams;
use Try::Tiny;
use JSON::MaybeXS;
use List::UtilsBy qw/zip_by/;

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

    push @{$c->stash->{header}->{css}}, '/static/modules/sysinfo/sysinfo.css';
    push @{$c->stash->{header}->{css}}, '/static/modules/sysinfo/fontawesome/font-awesome.min.css';
    push @{$c->stash->{header}->{js}}, '/static/modules/sysinfo/sysinfo.js';
    my $schema = $c->model('SysParams')->schema;
    $c->stash->{sys_params} = OpusVL::SysParams->new({ schema => $schema });

	$c->stash->{urls} =
	{
		sys_info_list => sub { $c->uri_for ( $self->action_for ('list_params')      ) },
		sys_info_set  => sub { $c->uri_for ( $self->action_for ('set_param'), shift ) },
		sys_info_set_ta  => sub { $c->uri_for ( $self->action_for ('set_textarea_param'), shift ) },
		sys_info_set_json  => sub { $c->uri_for ( $self->action_for ('set_json_param'), shift ) },
		sys_info_del  => sub { $c->uri_for ( $self->action_for ('del_param'), shift ) },
		sys_info_new  => sub { $c->uri_for ( $self->action_for ('new_param') ) },
        sys_info_comment => sub { $c->uri_for ($self->action_for ('set_comment'), shift ) },
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
	
    my $grouped = $c->config->{'Model::SysParams'}->{group_sysparams};
	$c->stash->{sys_info} = $c->model('SysParams::SysInfo')->ordered;

    if ($grouped) {
        my $groups = {};
        for my $setting ($c->stash->{sys_info}->all) {
            my @path = split /\./, $setting->name;
            my $node = $groups;

            while (@path) {
                my $name = shift @path;
                my $path = $node->{path} || '';
                $node->{children}->{$name} //= {};

                $node = $node->{children}->{$name};
                $node->{path} ||= join '.', grep {$_} $path, $name;
            }

            $node->{param}   = $setting;
        }

        $c->stash->{sys_info} = $groups;
    
        $c->stash->{template} = 'modules/sysinfo/list_params_grouped.tt';
    }

    $c->stash->{pretty_json} = sub {
        JSON->new->pretty->ascii(0)->encode($_[0]);
    };
}

sub set_param
	: Path('set')
	: Args(1)
	: AppKitForm
    : AppKitFeature('System Parameters')
{
	my $self  = shift;
	my $c     = shift;
	my $name = shift;
    my $param = $c->model('SysParams::SysInfo')->find({
        name => $name
    });

	if ($c->req->param ('cancelbutton'))
	{
		$c->flash->{status_msg} = 'System Parameter not Changed';
		$c->res->redirect($c->stash->{urls}->{sys_info_list}->());
		$c->detach;
	}

    $self->_set_param($c, $param);

    $c->flash->{status_msg} = 'System Parameter Successfully Altered';
    $c->res->redirect($c->stash->{urls}{sys_info_list}->());
    $c->detach;
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

	if ($c->req->param ('cancelbutton'))
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
	: AppKitForm(modules/sysinfo/set_param.yml)
    : AppKitFeature('System Parameters')
{
	my $self  = shift;
	my $c     = shift;
	my $form  = $c->stash->{form};

	if ($c->req->param ('cancelbutton'))
	{
		$c->flash->{status_msg} = 'System Parameter Not Set';
		$c->res->redirect($c->stash->{urls}{sys_info_list}->());
		$c->detach;
	}
	
    $form->get_all_element('name')->type('Text');
    $form->process;
    $c->stash->{template} = 'modules/sysinfo/set_param.tt';

    $self->_set_param($c, $c->model('SysParams::SysInfo')->new_result({}));

    $c->flash->{status_msg} = 'System Parameter Successfully Created';
    $c->res->redirect($c->stash->{urls}{sys_info_list}->());
    $c->detach;
}

sub set_comment
    : Path('set_comment')
    : Args(1)
    : AppKitForm
    : AppKitFeature('System Parameters')
{
    my $self = shift;
    my $c = shift;
	my $name = shift;
	my $form  = $c->stash->{form};
    my $param = $c->model ('SysParams::SysInfo')->find_or_create({
        name => $name
    });

    my $return_url = $c->stash->{urls}->{sys_info_list}->();

	$form->default_values
	({
		name  => $name,
        comment => $param->comment
	});

    if ($form->submitted_and_valid) {
        $param->update({comment => $form->param_value('comment')});
		$c->flash->{status_msg} = "Comment updated";
		$c->res->redirect($return_url);
		$c->detach;
    }
}

sub _set_param {
    my ($self, $c, $param) = @_;

    my $form = $c->stash->{form};

    # this for ordering purposes.
    my $data_types = $c->model('SysParams::SysInfo')
        ->result_source
        ->column_info('data_type')
        ->{extra}
        ->{list};

    my %data_type_options = zip_by { @_ }
        $data_types,
        $c->model('SysParams::SysInfo')->result_source->column_info('data_type')->{extra}->{labels}
    ;
    my %actual_options = map { $_ => $data_type_options{$_} } @{ $param->viable_type_conversions };

    $form->get_all_element({ name => 'data_type' })->options([
        map { +{
            value => $_,
            label => $actual_options{$_},
            label_attributes => { title => $actual_options{$_} }
        } } 
        grep { exists $actual_options{$_} } @$data_types
    ]);
    $form->process;

	my $return_url = $c->stash->{urls}{sys_info_list}->();

	if ($form->submitted_and_valid)
	{
        my $type = $c->req->body_params->{'data_type'};
        my $name = $c->req->body_params->{'name'};

        my $update = {
            name => $name,
            data_type => $type,
            label => $c->req->body_params->{'label'},
            comment => $c->req->body_params->{'comment'},
        };
        if ($type eq 'object') {
            $update->{value} = $c->req->body_params->{value_json};
        }
        elsif ($type eq 'boolean') {
            my $tf = $c->req->body_params->{value} ? JSON->true : JSON->false;
            $update->{value} = JSON->new->allow_nonref->encode($tf);
        }
        else {
            $update->{value} = JSON->new->allow_nonref->encode($c->req->body_params->{value});
        }
        $param->set_columns($update);

        my $updated_ok = try {
            if ($param->in_storage) {
                $param->update;
            }
            else {
                $param->insert;
            }
            1;
        }
        catch {
            $c->log->debug(__PACKAGE__ . '->set_json_param exception: ' . $_);

            if (/UNIQUE/i) {
                $c->stash->{error_msg} = "Parameter $name already exists";
            }
            else {
                $form->get_field('value')->get_constraint({ type => 'Callback' })->force_errors(1);
            }
            $form->process;
            0;
        };

        return if $updated_ok;
	}

    # Make sure a suitable type is available, for old entries
    $param->set_type_from_value
        if ! $param->data_type
        and defined $param->value;

	$form->default_values
	({
		name  => $param->name,
        value => scalar $param->decoded_value,
        label => $param->label,
        comment => $param->comment,
        data_type => $param->data_type // 'text',
	});

    $c->stash->{param} = $param;
    $c->stash->{pretty_json} = sub {
        JSON->new->allow_nonref->pretty->ascii(0)->encode($_[0]);
    };
    $c->detach;
}

1;


=head1 NAME

OpusVL::AppKitX::SysParams::Controller::SysInfo

=head1 DESCRIPTION

=head1 METHODS

=head2 auto

=head2 list_params

=head2 set_textarea_param

=head2 set_param

=head2 set_json_param

=head2 del_param

=head2 new_param

=head2 set_comment

=head1 ATTRIBUTES


=head1 LICENSE AND COPYRIGHT

Copyright 2012 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut
