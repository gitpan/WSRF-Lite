#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#

# This version of the Counter uses a process to store and handle its
# state. It is created by the Counterfactory service.

package Counter;
use strict;
use vars qw(@ISA);
use WSRF::Lite;

@ISA = qw(WSRF::WSRL);

# If these $ENV are set the SOAP message will be signed
# Points to the public key of the X509 certificate
#$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/hostcert.pem";
# Points to the provate key of the cert - must be unencrypted
#$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/hostkey.pem";
# Tells WSRF::Lite to sign the message with the above cert
#$ENV{WSS_SIGN} = 'true';


# Define our ResourceProperties count and foo. 
$WSRF::WSRP::ResourceProperties{count} = 0;
# prefix used when creating XML messages for count
$WSRF::WSRP::PropertyNamespaceMap->{count}{prefix} = "mmk";
# namespace for count property - count will look like the following on the wire
# <mmk:count xmlns:mmk="http://www.sve.man.ac.uk/Counter">0</mmk:count>
$WSRF::WSRP::PropertyNamespaceMap->{count}{namespace} = 
   "http://www.sve.man.ac.uk/Counter";
# Here we say count cannot be deleted, modified or inserted using the standard 
# WSRP operation SetResourceProperties   
$WSRF::WSRP::NotDeletable{count}  = 1;
$WSRF::WSRP::NotModifiable{count} = 1;
$WSRF::WSRP::NotInsert{count} = 1;

# foo is an array of things - because we did not set NotDeletable or
# NotModifiable we can update/insert/delete foo properties using 
# SetResourceProperties
$WSRF::WSRP::ResourceProperties{foo} = [];
$WSRF::WSRP::PropertyNamespaceMap->{foo}{prefix} = "mmk";
$WSRF::WSRP::PropertyNamespaceMap->{foo}{namespace} = 
   "http://www.sve.man.ac.uk/Counter";

# bar is a blessed HASH - the HASH will be serialized automatically for us
# When using getResourceProperties the XML will look like:
# <mmk:bar xmlns:mmk="http://www.sve.man.ac.uk/Counter"><BAR><foo>mmmh</foo></BAR></mmk:bar>
# If you are going to do this kind of thing then maybe you should
# use SOAP::Data objects rather than plain blessed HASHs   
$WSRF::WSRP::ResourceProperties{bar} = bless { foo => "mmmh" }, "BAR";
$WSRF::WSRP::PropertyNamespaceMap->{bar}{prefix} = "mmk";
$WSRF::WSRP::PropertyNamespaceMap->{bar}{namespace} =
   "http://www.sve.man.ac.uk/Counter";
   
   
  
# we will override the default init method to set a default TT time - 
# the init method is called when the service is created.
sub init {
  my $self = shift @_;
  alarm(60*60);     #TT = 1hour 
  
  $self->SUPER::init();

  #this will be sent to the log file
  print "New Counter created at ".time."\n";
  print "Counter value = $WSRF::WSRP::ResourceProperties{count}\n";
  $WSRF::WSRP::ResourceProperties{TerminationTime} = 
     WSRF::Time::ConvertEpochTimeToString( time + 60*60 );
  return;
}


# add a value to the count
sub add {
  my $envelope = pop @_;     #get the SOAP envlope
 
  #we can access the raw XML of the SOAP message using $envelope->raw_xml
  #useful if you want to parse the XML using DOM etc....
  #print "_xml>>>>\n".$envelope->raw_xml."<<<_xml\n";
  
  my ($class, $val) = @_;   #get the params to the operation
    
  $WSRF::WSRP::ResourceProperties{count} = 
     $WSRF::WSRP::ResourceProperties{count} + $val;

  #This will go to the log file
  print "Attempt to add $val at ".time."\n";
  print "Counter value = $WSRF::WSRP::ResourceProperties{count}\n";
     
  return WSRF::Header::header($envelope),
         $WSRF::WSRP::ResourceProperties{count};

}



sub subtract {
  my $envelope = pop @_;
  my ($class, $val) = @_;
  
  $WSRF::WSRP::ResourceProperties{count} = 
     $WSRF::WSRP::ResourceProperties{count} - $val;  
    
  #This will go to the log file
  print "Attempt to subtract $val at ".time."\n";
  print "Counter value = $WSRF::WSRP::ResourceProperties{count}\n";

  return  WSRF::Header::header($envelope), 
          $WSRF::WSRP::ResourceProperties{count};
}


sub getValue {
  return WSRF::Header::header(pop @_),
  $WSRF::WSRP::ResourceProperties{count};
}

#We only allow TerminationTime and count to be set by PutResourcePropertyDocument
sub PutResourcePropertyDocument {
   my $self = shift @_;
   my $envelope = pop @_;
      
   #check if "count" is in the SOAP envelope
   if (  $envelope->match("//Body//count")  )
   { 
     #found "count", update the ResourceProperty after making sure its an int,
     #do not want an injection of Javascript!
     $WSRF::WSRP::ResourceProperties{count} = int( $envelope->valueof("//Body//count") );
   }

   #check for TerminationTime   
   if ( $envelope->match("//Body//{$WSRF::Constants::WSRL}TerminationTime") )
   {
      #found TerminationTime, now try and use it to set the ResourceProperty,
      #if TerminationTime is no a good format an exception will be thrown
      eval {
               #Use the WSRF SetTerminationTime operation on self, it    
               #expects a value and an envelope
               $self->SetTerminationTime(
                   $envelope->valueof("//Body//{$WSRF::Constants::WSRL}TerminationTime"),
                         $envelope);
      };
      if ( $@ )   #bad TerminationTime, catch exception
      {
         print "Attempt to update TerminationTime with bad value\n $@";
      }
   }

   #need to return the new verision of the ResourcePropertyDocument,
   #call the WSRF operation GetResourcePropertyDocument on self.
   return $self->GetResourcePropertyDocument($envelope);
}




1;
