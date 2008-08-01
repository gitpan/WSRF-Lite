#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#

# For this Counter example a single process manages the state for a number
# of Counter Resources. The process mentains a hash holding all the properties
# for all the reources - the ReourceID is used as a key to the hash. 

# If these $ENV are set the SOAP message will be signed
# # Points to the public key of the X509 certificate
# #$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/hostcert.pem";
# # Points to the provate key of the cert - must be unencrypted
# #$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/hostkey.pem";
# # Tells WSRF::Lite to sign the message with the above cert
# #$ENV{WSS_SIGN} = 'true';
#



package Counter;

use WSRF::Lite;

use strict;

use vars qw(@ISA);

@ISA = qw(WSRF::MultiResourceLifetimes);


sub createCounterResource { 
  #get the envelope 
  my $envelope = pop @_;

# This will print the raw xml of the SOAP Envelope to the log files:
#  print "Envelope>>>\n".$envelope->raw_xml."\n<<<Envelope\n";

  #Get a Reource ID - just use big random number for  resource id
  my $ResourceId = WSRF::GSutil::CalGSH_ID();


  #Add TerminationTime as a reource property -
  #initalise to nothing (equivalent to setting a Termination Time to infinity)
  $WSRF::MultiResourceProperties::ResourceProperties->{$ResourceId}{TerminationTime} = "";
  #belongs to ResourceLiftetime namespace - defined elsewhere to be wsrl
  $WSRF::MultiResourceProperties::PropertyNamespaceMap->{TerminationTime}{prefix} = "wsrl";
  #the TerminationTime can be nil
  $WSRF::MultiResourceProperties::Nillable{TerminationTime} = 1;


  #add resource property foo - foo is set to an array of things - ie
  #there can be mutliple foo's 
  $WSRF::MultiResourceProperties::ResourceProperties->{$ResourceId}{foo} = [];
  $WSRF::MultiResourceProperties::PropertyNamespaceMap->{foo}{prefix} = "count";
  $WSRF::MultiResourceProperties::PropertyNamespaceMap->{foo}{namespace} =
                            "http://www.sve.man.ac.uk/Counter";
  #To make foo be not deletable and readonly uncomment the following lines
  #$WSRF::MultiResourceProperties::NotDeletable{foo} = 1;
  #$WSRF::MultiResourceProperties::NotModifiable{foo} = 1;

  #add resource property count and set to zero
  $WSRF::MultiResourceProperties::ResourceProperties->{$ResourceId}{count} = 0;
  $WSRF::MultiResourceProperties::PropertyNamespaceMap->{count}{prefix} = "count";
  $WSRF::MultiResourceProperties::PropertyNamespaceMap->{count}{namespace} =
                           "http://www.sve.man.ac.uk/Counter";
  #we make count so that is readonly and cannot be deleted or inserted using 
  #SetResourceProperties - 
  #count can only be changed using the add/subtract operations defined below
  $WSRF::MultiResourceProperties::NotDeletable{count} = 1;
  $WSRF::MultiResourceProperties::NotModifiable{count} = 1;
  $WSRF::MultiResourceProperties::NotInsert{count} = 1;

  #add resource property CurrentTime - in this
  #case a subroutine that returns the current
  #time in the correct format
  $WSRF::MultiResourceProperties::ResourceProperties->{$ResourceId}{'CurrentTime'} =
     sub {  return "<wsrl:CurrentTime>".
                     WSRF::Time::ConvertEpochTimeToString().
		   "</wsrl:CurrentTime>";     };
  $WSRF::MultiResourceProperties::PropertyNamespaceMap->{CurrentTime}{prefix} = "wsrl";
  #By default if a resource property is a subroutine
  #then you cannot change it or delete it - however
  #for completeness we set the following
  $WSRF::MultiResourceProperties::NotDeletable{CurrentTime} = 1;
  $WSRF::MultiResourceProperties::NotModifiable{CurrentTime} = 1;

  #create a WS-Address and return it.
  my $wsa  =  WSRF::GSutil::createWSAddress( module => 'Counter',
                                             path   => 'MultiSession/Counter',
    					     ID     => $ResourceId );

  
  
  #create a SOAP::Header object using the envelope and header sub - 
  #return it and the response 
  return  WSRF::Header::header( $envelope ),  SOAP::Data->value($wsa)->type('xml');
}


# add operation
sub add {
  my $envelope = pop @_;
  
  #This function will get the ResourceID from the SOAP Header in
  #the SOAP envelope - it will check that the resource is in the
  #hash (or die with ERROR), check that the resource has not expired
  #(or die with ERROR) and return the ID.  
  my $ID = WSRF::MultiResourceProperties::getID($envelope);
  
  my ($class, $val) = @_;    #get the paramaters to the operation
  
  $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{count} = 
     $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{count} + $val;
     
  return WSRF::Header::header($envelope),
         $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{count};

}

sub subtract {
  my $envelope = pop @_;
  my $ID = WSRF::MultiResourceProperties::getID($envelope); 
  my ($class, $val) = @_;
  
  $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{count} = 
     $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{count} - $val;  
    
  return  WSRF::Header::header($envelope), 
          $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{count};

}


sub getValue {
  my $envelope = pop @_;
  my $ID = WSRF::MultiResourceProperties::getID($envelope);
 
  return WSRF::Header::header($envelope),
         $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{count};
}



sub PutResourcePropertyDocument {
   my $self = shift @_;
   my $envelope = pop @_;

   my $ID = WSRF::MultiResourceProperties::getID($envelope);

   if (  $envelope->match("//Body//count")  )
   {
     $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{count} = int( $envelope->valueof("//Body//count") );
   }

   if ( $envelope->match("//Body//{$WSRF::Constants::WSRL}TerminationTime") )
   {
      eval {
                $self->SetTerminationTime(
                   $envelope->valueof("//Body//{$WSRF::Constants::WSRL}TerminationTime"),
                         $envelope);
      };
      if ( $@ )
      {
         print "Attempt to update TerminationTime with bad value\n $@";
      }
   }
   return $self->GetResourcePropertyDocument($envelope);
}






1;
