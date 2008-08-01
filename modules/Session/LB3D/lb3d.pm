#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#

BEGIN {
   @INC = ( @INC, "/usr/lib/perl5/5.8.3/i386-linux-thread-multi/",
                  "/usr/lib/perl5/5.8.3/" );
};


package lb3d;
use WSRF::Lite;
#needed to convert Iputfile from Base64 encoding
use MIME::Base64 ();
#needed to create "safe" temporay files
use File::Temp;
use strict;
use vars qw(@ISA);
#needed to allow us access to the SOAP envelope
@ISA = qw(SOAP::Server::Parameters);


#hash containing the set of allowed users
$lb3d::AllowedDNs{'/C=UK/O=eScience/OU=Manchester/L=MC/CN=mark mckeown'} = 1;
$lb3d::AllowedDNs{'/C=UK/O=eScience/OU=Manchester/L=MC/CN=andrew porter'} = 1;


#File that holds the JobID & user DN who started the job
$lb3d::state = "/tmp/wsrf/data/lb3d";
$lb3d::lock = "/tmp/wsrf/data/lb3d.lock";


my $authenticate = sub {
   print "DN = ".$ENV{SSL_CLIENT_DN}."\n";
   if ( !defined( $lb3d::AllowedDNs{$ENV{SSL_CLIENT_DN}} ) ) 
   {
      die $ENV{SSL_CLIENT_DN}." not authorised";
   }
};



#INput for LaunchSimulation looks like:
#<LaunchSimulation>
#  <TargetHostname/>
#  <TargetHostJobManager/>
#  <RunTime/>
#  <CheckPointGSH/>?
#  <NoProcessors/>
#  <SimualationInputFiles>
#     <File>*
#       <!-- Base64 encoded file --!>
#     <File>
#  </SimualationInputFiles>
#  <SimulationSTDOUTfile/>
#  <SimulationSTDERRfile/>
#  <ReGSGSAddress/>?
#</LaunchSimulation>
sub LaunchSimulation {
  #check user is authorized 
  $authenticate->();

  #random number - used as identifier
  my $num = int(rand 100000) + 1;
  $num = join('',gmtime).$num;

  
  #get the SOAP envelope - we will parse it ourselves
  #the $envelope is a SOAP::SOM object, man SOAP::SOM
  my $envelope = pop @_;
 
  #get the TargetHostName
  my $TargetHostname = defined($envelope->match('//TargetHostname/')) ?
                       $envelope->valueof('//TargetHostname/') :
		       die "No TargetHostname\n";
  #check the hostname is safe
  if ( $TargetHostname =~ /^([\w+\.]+)$/)
  {
     $TargetHostname = $1;
     print "TargetHostName= $TargetHostname\n";	  
  }	  
  else
  {
     die "Bad Target Hostname $TargetHostname\n";	   
  }	  
		       
  #get the TargetHostJobManager		       
  my $TargetHostJobManager = defined($envelope->match('//TargetHostJobManager/')) ?
                       $envelope->valueof('//TargetHostJobManager/') :
		       die "No TargetHostJobManager\n";
  #check Target Host Jobmanager is safe		       
  if ( $TargetHostJobManager =~ /^([-\w]+)$/)
  {
      $TargetHostJobManager = $1;
      print "TargetHostJobManager= $TargetHostJobManager\n";
  }
  else
  {
      die "Bad Target Host JobManager $TargetHostJobManager\n";          
  }       

  #get the runtime		       
  my $RunTime = defined($envelope->match('//RunTime/')) ?
                        $envelope->valueof('//RunTime/') :
		       die "No RunTime\n";		       
  if( $RunTime eq "" )
  {
    die "No RunTime\n"; 
  }
  print "RunTime= $RunTime\n";	
	
  #if a checpoint GSH is defined we are starting from
  #a checkpoit and no input file is required	
  my ($CheckPointGSH, $InputFile, $tmpInputFile);
  if ( defined( $envelope->match('//CheckPointGSH/') ) )
  {
    #job will be started from checkpoint
    $CheckPointGSH = $envelope->valueof('//CheckPointGSH/');
  }
  else #job will be started from an input file
  {
     #lb3d only has one input file!!
     my $InputFile = defined($envelope->match('//SimualationInputFile/[1]')) ?
                       $envelope->valueof('//SimualationInputFile/[1]') :
		       die "No InputFile or CheckPoint GSH\n";	    
     #convert InputFile from Base64 encoding
     $InputFile = MIME::Base64::decode($InputFile);
     #now put the InputFile into a "safe" tempory file
     $tmpInputFile = new File::Temp(UNLINK => 1);
     print "InputFile>>>\n$InputFile\n<<<<InputFile\n";
     print $tmpInputFile $InputFile;
     print "Tempory Input File is $tmpInputFile\n";     
  }		       
  
  #get Number of processors
  my $NoProcessors = defined($envelope->match('//NoProcessors/')) ?
                     $envelope->valueof('//NoProcessors/') :
     		     die "Number of Processors defined\n";
  if ( $NoProcessors =~ /^(\d+)$/ )
  {
      $NoProcessors = $1;
      print "No of Processors requested= $NoProcessors\n";	  
  }
  else
  {
      die "Number of Processors should be a number\n";	   
  }	  

  
  #get the name of the Simulation STDOUT file		     
  my $SimulationSTDOUTfile = defined($envelope->match('//SimulationSTDOUTfile/')) ?
                       $envelope->valueof('//SimulationSTDOUTfile/') :
		       die "No Simulation STDOUT file defined\n";	  
  print "Simulation STDOUT file is $SimulationSTDOUTfile\n";
  
  #get the name of the Simulation STDERR file
  my $SimulationSTDERRfile = defined($envelope->match('//SimulationSTDERRfile/')) ?
                       $envelope->valueof('//SimulationSTDERRfile/') :
		       die "No Simulation STDERR file defined\n";	  
  print "Simulation STDERR file is $SimulationSTDERRfile\n";
  
  
  #get the SGS address for the service
  my $ReGSGSAddress = defined($envelope->match('//ReGSGSAddress/')) ?
                       $envelope->valueof('//ReGSGSAddress/') : "";	  
  print "SGS Address is $ReGSGSAddress\n";
  
  #if we are using a checkpoint copy it to the target otherwise copy
  #over the inpuf file
  my ($out);
  if ( $CheckPointGSH ne "" )
  { #check the GSH is safe
    if ($CheckPointGSH =~ /^(http:\/\/[\.-\w\/]+)$/ )
    {
       $CheckPointGSH = $1;	    
       print "CheckPoint is $CheckPointGSH\n";	    
    }
    else
    {
       die "Bad ChekPoint GSH $CheckPointGSH\n"; 
    }
    print "Copying CheckPoint to $TargetHostname... ";	    
    $out = `/home/zzcgumk/reg_qt_launcher/scripts/rg-cp -vb -p 10 -tcp-bs 16777216 -t gsiftp://$TargetHostname/~/RealityGrid/scratch -g $CheckPointGSH`;	   
    print "$out\n";
  }
  else  #copy over input file
  {
    print "Copying InputFile to ~/RealityGrid/scratch/.reg.input-file.$num on $TargetHostname...";
    $out = `/home/globus/vdt/globus/bin/globus-url-copy file:///$tmpInputFile gsiftp://$TargetHostname/\~/RealityGrid/scratch/.reg.input-file.$num`;
    print "$out\n";	  
  }  
  

  #create the script we are going to run on the target machine
  my $REG_TMP_FILE = new File::Temp(UNLINK => 1);   #file we will put script into
  my $script = "#!/bin/sh\n";
  $script .= ". \$HOME/RealityGrid/etc/reg-user-env.sh\n";
  $script .= "REG_WORKING_DIR=\$HOME/RealityGrid/scratch\n" ;
  $script .= "export REG_WORKING_DIR\n" ;
  $script .= "SSH=\$SSH\n" ;
  $script .= "export SSH\n" ;
  $script .= "REG_STEER_DIRECTORY=\$REG_WORKING_DIR\n" ;
  $script .= "export REG_STEER_DIRECTORY\n" ;
  $script .= "print \"Working directory is \$REG_WORKING_DIR\"\n" ;
  $script .= "print \"Steering directory is \$REG_STEER_DIRECTORY\"\n" ;
  $script .= "if [ ! -d \$REG_WORKING_DIR ]\n" ;
  $script .= "then\n" ;
  $script .= "  mkdir \$REG_WORKING_DIR\n" ;
  $script .= "fi\n" ;
  $script .= "cd \$REG_WORKING_DIR\n" ;
  $script .= "if [ ! -e \$HOME/RealityGrid/scratch/.reg.input-file.$num ]\n" ;
  $script .= "then\n" ;
  $script .= "  print \"Input file not found - exiting\"\n" ;
  $script .= "  exit\n" ;
  $script .= "fi\n" ;
  $script .= "mv -f \$HOME/RealityGrid/scratch/.reg.input-file.$num .\n" ;
  $script .= "chmod a+w .reg.input-file.$num\n" ;
  $script .= "UC_PROCESSORS=$NoProcessors\n" ;
  $script .= "export UC_PROCESSORS\n" ;
  $script .= "TIME_TO_RUN=$RunTime\n" ;
  $script .= "export TIME_TO_RUN\n" ;
  $script .= "GS_INFILE=.reg.input-file.$num\n" ;
  $script .= "export GS_INFILE\n" ;
  $script .= "SIM_STD_ERR_FILE=$SimulationSTDERRfile\n" ;
  $script .= "export SIM_STD_ERR_FILE\n" ;
  $script .= "SIM_STD_OUT_FILE=$SimulationSTDOUTfile\n" ;
  $script .= "export SIM_STD_OUT_FILE\n" ;
  $script .= "REG_SGS_ADDRESS=$ReGSGSAddress\n" ;
  $script .= "export REG_SGS_ADDRESS\n" ;
  $script .= "print \"Starting mpi job...\"\n" ;
  $script .= "\$HOME/RealityGrid/bin/lbe3d\n" ;
  print "script>>>\n$script\n<<<script\n";
  
  #put the script into the file
  print $REG_TMP_FILE $script;

  #create the RSL file 
  my $tmpRSLFile = new File::Temp(UNLINK => 1);
  my $RSL = "&(executable=\$(GLOBUSRUN_GASS_URL)/$REG_TMP_FILE)(jobtype=single)(maxWallTime=$RunTime)(stdout=$SimulationSTDOUTfile)(stderr=$SimulationSTDERRfile)(count=$NoProcessors)";
  print $tmpRSLFile $RSL;

  #start the job
  print "/home/globus/vdt/globus/bin/globusrun -b -s -r $TargetHostname/$TargetHostJobManager -f $tmpRSLFile &\n";
  $out = `/home/globus/vdt/globus/bin/globusrun -b -s -r $TargetHostname/$TargetHostJobManager -f $tmpRSLFile &`;
  chomp $out;
 
  print "Job Contact: $out\n";
  
  my $filelock = new WSRF::FileLock($lb3d::lock);
  open (STATE, ">>$lb3d::state");
  print STATE $ENV{SSL_CLIENT_DN}."|$out|$num\n"; 
  close STATE or die "Cannot close $lb3d::state\n";
    
  return $num;  
}




my $getID = sub {
  #check user is authorized 
  my ($ID) = @_;
  my $DN = $ENV{SSL_CLIENT_DN};
  my $GlobusID = "";

  my $filelock = new WSRF::FileLock($lb3d::lock);
  open (STATE, "<$lb3d::state") or die "Cannot open $lb3d::state\n";
  while ( <STATE> )
  {
     
     my ($UDN, $GJID, $JID) = split /\|/;
     print "$UDN, $GJID, $JID\n";
     chomp $JID;
     if (  $JID eq $ID )
     {
        if ( $DN eq  $UDN )
	{
	  $GlobusID = $GJID;
	}
	else
	{
	   die "$DN does not own job $ID\n";
	}
     }
  }
  close STATE or die "Cannot close $lb3d::state\n";
  $filelock->DESTROY;
  
  if( $GlobusID eq "" )
  {
      die "no such job $ID\n";
  }
  

  return $GlobusID;  
};


sub Cancel {
  #check user is authorized 
  $authenticate->();
  my ($self, $ID) = @_;
  my $GlobusID = $getID->($ID);
  
  print "/home/globus/vdt/globus/bin/globus-job-cancel -f $GlobusID\n";
  my $out = `/home/globus/vdt/globus/bin/globus-job-cancel -f $GlobusID`;
  chomp $out;
  return $out  

}


sub Status {
  #check user is authorized 
  $authenticate->(); 
  my ($self, $ID) = @_;
  my $GlobusID = $getID->($ID);

  print "/home/globus/vdt/globus/bin/globus-job-status $GlobusID\n";
  my $out = `/home/globus/vdt/globus/bin/globus-job-status $GlobusID`;
  chomp $out;
  return $out
}



sub Clean {
  #check user is authorized 
  $authenticate->();
  my ($self, $ID) = @_;
  my $GlobusID = $getID->($ID);
  
  print "/home/globus/vdt/globus/bin/globus-job-clean -f $GlobusID\n";
  my $out = `/home/globus/vdt/globus/bin/globus-job-clean -f $GlobusID`;
  chomp $out;
  return $out  
}




1;
