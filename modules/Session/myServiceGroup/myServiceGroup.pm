#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#


package myServiceGroup;
use strict;
use vars qw(@ISA);
use WSRF::Lite;

#
# We inherit all the functionality for the ServiceGroup from
# WSRF::ServiceGroup - this uses a file to store the state of
# the servicegroup and the servicegroupentries 
#
# Note by default WSRF::ServiceGroup uses the
# /modules/ServiceGroupEntry/ServiceGroupEntry.pm module   
@ISA = qw(WSRF::ServiceGroup);


# Other RPs can be defined here - they can be initalised using
# the createServiceGroup operation below.


# operation to create a new ServiceGroup - note WS-ServiceGroup
# spec does not define a method for creating a new ServiceGroup
# so we must define our own.
sub createServiceGroup {
  my $envelope = pop @_;
  my ($class, @params) = @_;


  # get an ID for the Resource
  my $ID = WSRF::GSutil::CalGSH_ID();
 
  #create a WS-Address for the Resource
  my $wsa  =  WSRF::GSutil::createWSAddress( module=> 'myServiceGroup',
                                             path  => 'Session/myServiceGroup/',
                                             ID => $ID );

  # We need to set this property - it is used by the ServiceGroupEntry -
  # it is one of the required RPs
  $WSRF::WSRP::ResourceProperties{ServiceGroupEPR} = $wsa;


  #write the properties to a file - note we use the non object
  #orientated way to do this - WSRF::File supports both ways
  #of accessing the module. If we call toFile in a non-OO way
  # we need to pass in the ID.
  WSRF::File::toFile($ID);
  
  #return the WS-Address
  return WSRF::Header::header( $envelope ),
           SOAP::Data->value($wsa)->type('xml');
}


1;
