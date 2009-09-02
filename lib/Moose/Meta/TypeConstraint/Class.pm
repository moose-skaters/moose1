package Moose::Meta::TypeConstraint::Class;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';
use Moose::Util::TypeConstraints ();

our $VERSION   = '0.89_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('class' => (
    reader => 'class',
));

sub new {
    my ( $class, %args ) = @_;

    $args{parent} = Moose::Util::TypeConstraints::find_type_constraint('Object');
    my $self      = $class->_new(\%args);

    $self->_create_hand_optimized_type_constraint;
    $self->compile_type_constraint();

    return $self;
}

sub _create_hand_optimized_type_constraint {
    my $self = shift;
    my $class = $self->class;
    $self->hand_optimized_type_constraint(
        sub {
            blessed( $_[0] ) && $_[0]->isa($class)
        }
    );
}

sub parents {
    my $self = shift;
    return (
        $self->parent,
        map {
            # FIXME find_type_constraint might find a TC named after the class but that isn't really it
            # I did this anyway since it's a convention that preceded TypeConstraint::Class, and it should DWIM
            # if anybody thinks this problematic please discuss on IRC.
            # a possible fix is to add by attr indexing to the type registry to find types of a certain property
            # regardless of their name
            Moose::Util::TypeConstraints::find_type_constraint($_)
                ||
            __PACKAGE__->new( class => $_, name => "__ANON__" )
        } Class::MOP::class_of($self->class)->superclasses,
    );
}

sub equals {
    my ( $self, $type_or_name ) = @_;

    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    return unless defined $other;
    return unless $other->isa(__PACKAGE__);

    return $self->class eq $other->class;
}

sub is_a_type_of {
    my ($self, $type_or_name) = @_;

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    ($self->equals($type) || $self->is_subtype_of($type_or_name));
}

sub is_subtype_of {
    my ($self, $type_or_name_or_class ) = @_;

    if ( not ref $type_or_name_or_class ) {
        # it might be a class
        return 1 if $self->class->isa( $type_or_name_or_class );
    }

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name_or_class);

    return unless defined $type;

    if ( $type->isa(__PACKAGE__) ) {
        # if $type_or_name_or_class isn't a class, it might be the TC name of another ::Class type
        # or it could also just be a type object in this branch
        return $self->class->isa( $type->class );
    } else {
        # the only other thing we are a subtype of is Object
        $self->SUPER::is_subtype_of($type);
    }
}

# This is a bit counter-intuitive, but a child type of a Class type
# constraint is not itself a Class type constraint (it has no class
# attribute). This whole create_child_type thing needs some changing
# though, probably making MMC->new a factory or something.
sub create_child_type {
    my ($self, @args) = @_;
    return Moose::Meta::TypeConstraint->new(@args, parent => $self);
}

sub get_message {
    my $self = shift;
    my ($value) = @_;

    if ($self->has_message) {
        return $self->SUPER::get_message(@_);
    }

    $value = (defined $value ? overload::StrVal($value) : 'undef');
    return "Validation failed for '" . $self->name . "' failed with value $value (not isa " . $self->class . ")";
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Class - Class/TypeConstraint parallel hierarchy

=head1 DESCRIPTION

This class represents type constraints for a class.

=head1 INHERITANCE

C<Moose::Meta::TypeConstraint::Class> is a subclass of
L<Moose::Meta::TypeConstraint>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::TypeConstraint::Class->new(%options) >>

This creates a new class type constraint based on the given
C<%options>.

It takes the same options as its parent, with two exceptions. First,
it requires an additional option, C<class>, which is name of the
constraint's class.  Second, it automatically sets the parent to the
C<Object> type.

The constructor also overrides the hand optimized type constraint with
one it creates internally.

=item B<< $constraint->class >>

Returns the class name associated with the constraint.

=item B<< $constraint->parents >>

Returns all the type's parent types, corresponding to its parent
classes.

=item B<< $constraint->is_subtype_of($type_name_or_object) >>

If the given type is also a class type, then this checks that the
type's class is a subclass of the other type's class.

Otherwise it falls back to the implementation in
L<Moose::Meta::TypeConstraint>.

=item B<< $constraint->create_child_type(%options) >>

This returns a new L<Moose::Meta::TypeConstraint> object with the type
as its parent.

Note that it does I<not> return a
C<Moose::Meta::TypeConstraint::Class> object!

=item B<< $constraint->get_message($value) >>

This is the same as L<Moose::Meta::TypeConstraint/get_message> except
that it explicitly says C<isa> was checked. This is to help users deal
with accidentally autovivified type constraints.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
