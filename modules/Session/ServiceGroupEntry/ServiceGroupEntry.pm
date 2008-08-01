#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#

#
# All the operations and RPs are defined in WSRF::ServiceGroupEntry
# - this module is very specialised (the ServiceGroup and ServiceGroupEntry
# use the same file to store their state) - so if you want to extend it
# you should look at WSRF::ServiceGroupEntry in the WSRF::Lite module.
#

package ServiceGroupEntry;
use strict;
use vars qw(@ISA);
use WSRF::Lite;

@ISA = qw(WSRF::ServiceGroupEntry);


1;
