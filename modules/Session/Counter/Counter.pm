#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#


package Counter;
use strict;
use vars qw(@ISA);
use WSRF::Lite;


# The version of the Counter inherits from the FileBasedResourceLifetimes class,
# this means that between calls the resource properties are stored in a file!!
# Only things that are in WSRF::WSRP::ResourceProperties are stored in the file,
# any other variables are lost. At the start of each operation the Properties are
# read from the file when the WSRF::File->new() is executed, a lock is put on the
# file so no other service can access the properties. The properties are written
# back to the file when WSRF::File::toFile is called. The lock is automatically
# destroyed when the object created by WSRF::File->new() goes out of scope - 
# ie you can die in an operation and not worry about clearing up the lock.
# When the file is read back in it is chaecked for a TT time - if the TT has expired
# the file is deleted and an ERROR returned. 

# If these $ENV are set the SOAP message will be signed
# # Points to the public key of the X509 certificate
# #$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/hostcert.pem";
# # Points to the provate key of the cert - must be unencrypted
# #$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/hostkey.pem";
# # Tells WSRF::Lite to sign the message with the above cert
# #$ENV{WSS_SIGN} = 'true';
#



@ISA = qw(WSRF::FileBasedResourceLifetimes);


# Set up the resource properties for this service count and foo. 
$WSRF::WSRP::ResourceProperties{count} = 0;
$WSRF::WSRP::PropertyNamespaceMap->{count}{prefix} = "mmk";
$WSRF::WSRP::PropertyNamespaceMap->{count}{namespace} = 
   "http://www.sve.man.ac.uk/Counter";
#prevent clients from inserting, deleting or modifiying count using
#the setresourceproperties operation
$WSRF::WSRP::NotDeletable{count}  = 1;
$WSRF::WSRP::NotModifiable{count} = 1;
$WSRF::WSRP::NotInsert{count} = 1;

# foo is an array of things
$WSRF::WSRP::ResourceProperties{foo} = [] ;
$WSRF::WSRP::PropertyNamespaceMap->{foo}{prefix} = "mmk";
$WSRF::WSRP::PropertyNamespaceMap->{foo}{namespace} = 
   "http://www.sve.man.ac.uk/Counter";

# This a hash for storing "private" data: data which we
# do not want to declare as a ResourceProperty but which 
# we want to store between invocations of the WS-Resource
# The hash is stored to file between calls to the WS-Resource. 
$WSRF::WSRP::Private{private} = 0;

   
# operation to create a new File based Counter
sub createCounterResource {
  my $envelope = pop @_;
  my ($class, @params) = @_;

  my $ser = new WSRF::SimpleSerializer;

#  print STDERR $ser->serialize( $envelope->dataof('//Body')  )."\n";


  # get an ID for the Resource
  my $ID = WSRF::GSutil::CalGSH_ID();
 
  #create a WS-Address for the Resource
  my $wsa  =  WSRF::GSutil::createWSAddress( module=> 'Counter',
                                             path  => 'Session/Counter/',
                                             ID => $ID );

  #write the properties to a file
  WSRF::File::toFile($ID);
  
  #return the WS-Address
  return WSRF::Header::header( $envelope ),
           SOAP::Data->value($wsa)->type('xml');
}


# add something to the counter
sub add {
  my $envelope = pop @_;                       #get the SOAP envelope
  my $lock = WSRF::File->new($envelope);       #get the properties from the file
  my ($class, $val) = @_;                      #get the operation paramaters

  
  $WSRF::WSRP::ResourceProperties{count} = 
     $WSRF::WSRP::ResourceProperties{count} + $val;  #perform the add
   
  $lock->toFile();                             #put the properties back in the file
  return WSRF::Header::header($envelope),      #return result
         $WSRF::WSRP::ResourceProperties{count};

}

sub subtract {
  my $envelope = pop @_;                       #get the SOAP envelope
  my $lock = WSRF::File->new($envelope);       #get the properties from the file
  my ($class, $val) = @_;                      #get the operation paramaters

  
  $WSRF::WSRP::ResourceProperties{count} =              #perform the subtraction
     $WSRF::WSRP::ResourceProperties{count} - $val;  

  $lock->toFile();                            #put the properties back in the file  
  return  WSRF::Header::header($envelope),    #return result
          $WSRF::WSRP::ResourceProperties{count};

}


sub getValue {
  my $envelope = pop @_;                      #get the properties from the file
  my $lock = WSRF::File->new($envelope);      #get the SOAP envelope
  
  #put the properties back in the file - don't really need to
  #put properties back in file since this is a read only operation 
  #but we do it anyway. 
  $lock->toFile();                             
    
  return WSRF::Header::header($envelope),     #return result
         $WSRF::WSRP::ResourceProperties{count};
}


# Each time we invoke this operation we increment $WSRF::WSRP::Private.
sub accessPrivate {
    my $envelope = pop @_;
    my $lock = WSRF::File->new($envelope);
       $WSRF::WSRP::Private{private}++;
    $lock->toFile();
    return WSRF::Header::header($envelope),     #return result
              $WSRF::WSRP::Private{private};
}


#unfortunately this is not an atomic operation
sub PutResourcePropertyDocument {
   my $self = shift @_;
   my $envelope = pop @_;


   my $lock = WSRF::File->new($envelope);      #get the SOAP envelope

   if (  $envelope->match("//Body//count")  )
   {
     $WSRF::WSRP::ResourceProperties{count} = int( $envelope->valueof("//Body//count") );
   }

   $lock->toFile();
   undef $lock;

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
