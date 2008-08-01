#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#


# This module creates a process based Counter Resource - effectively
# it forks of a new process with the target service deployed in the
# process. We communicate to the process using a named UNIX socket.

package CounterFactory;


use WSRF::Lite;
use strict;
use vars qw(@ISA);
@ISA = qw(SOAP::Server::Parameters);

sub createCounterResource {
  my $envelope = pop @_;
  my ($class, @params) = @_;

  #create a new Resource - we pass in the name of the module,
  #the path to the module and the namespace the service will use.
  #(Optionally we can pass an ID for the service - if we don't, it
  #creates one automatically for us) 
  my $newService = WSRF::Resource->new( module=> 'Counter',
	                                path  => '/WSRF/Counter',
					namespace => 'http://www.sve.man.ac.uk/Counter' );
  
  #we retieve the ID of the Resource here.
  my $resourceID = $newService->ID();
  
  #This is were the process is forked of - the init method is then
  #invoked on the service and the @params passed to it. 
  $newService->handle(@params);  
      
  #We can call other operations on the new service here - eg to
  #set the Termination time we could use:
  #  $newService->SetTerminationTime( $SomeProperTT );  
      
  #create a WS-Address for the new Resource    
  my $wsa  =  WSRF::GSutil::createWSAddress( module=> 'Counter',
                                             path  => '/WSRF/Counter/',
    					     ID => $resourceID );
                                          
      
  #return the WS-Address of the new Resource.
  return WSRF::Header::header( $envelope ),
           SOAP::Data->value($wsa)->type('xml');     
}

1;
