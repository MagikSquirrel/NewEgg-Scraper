#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use WWW::Mechanize;
use 5.010;

#Debugging tools
package My;

use constant {

#Category numberings
	CAT_MOBO => 20,
	CAT_POWER => 32,
	CAT_CPU => 34,
	CAT_VID => 38,

#SubCategory numberings
	SUB_CPU => 343,
	SUB_HDD_INT => 14,
	SUB_HDD_SSD => 636,
	SUB_MOBO_AMD => 22,
	SUB_MOBO_INTEL => 280,
	SUB_RAM => 147,
	SUB_VID => 48,
};

my $SQL_IP = "localhost";
my $SQL_Port = "3306";
my $SQL_User = "newegg";
my $SQL_Pass = "newegg";
my $SQL_Schema = "newegg";

sub TechTable {
	my $tech = shift;
	while(my($k,$v)=each(%$tech)){
		print "$k => $v\n";
	}
}
sub QuickProperty {
    my ( $variable, $object, $value ) = @_;
    $object->{$variable} = $value if defined($value);
    return $object->{$variable};
}

#PRIVATE METHOD - Removes excess spacing from a string
sub NoSpace {
	my $txt = shift;
	$txt =~ s/[ \t]{2,}/ /g; #Multiple spaces
	$txt =~ s/^ +//; #Starting spaces
	$txt =~ s/ +$//; #Ending spaces
	return $txt
}

#PRIVATE METHOD - Removes HTML formatting from a string
sub NoHTML {
	my $txt = shift;
	$txt =~ s/<[a-zA-Z\/][^>]*>//g;
	return $txt
}

#Private Method - Connect to the SQL server
sub SqlConnect{
	return DBI->connect("dbi:mysql:database=$SQL_Schema;host=$SQL_IP;port=$SQL_Port", $SQL_User, $SQL_Pass)
		or sub { warn "Unable to connect to DB"; return undef; };
}

##################################################
##        __   ___  __      __        __   __  
##\  / | |  \ |__  /  \    /  `  /\  |__) |  \ 
## \/  | |__/ |___ \__/    \__, /~~\ |  \ |__/ 
##                                                                                                                 
##################################################
package Component::VideoCard;

#PUBLIC CONSTRUCTOR - Base constructor for ram object
#				allows population now if we have the hash
sub new {

	#Optional Population
	my ($class, $parent, $hashref) = @_;

	my $self = {
		__parent => $parent,
		_iface => undef, #Interface
		_chpman => undef, #Chipset Manufacturer
		_gpu => undef, #GPU
		_coreclk => undef, #Core Clock
		_shadeclk => undef, #Shader Clock
		_procst => undef, #Stream Processors
		_memclk => undef, #Effective Memory Clock
		_memsize => undef, #Memory Size
		_memif => undef, #Memory Interface
		_memtype => undef, #Memory Type
		_dx => undef, #DirectX
		_ogl => undef, #OpenGL
		_hdmi => undef, #HDMI
		_dvi => undef, #DVI
		_vga => undef, #VGA
		_sli => undef, #SLI Support
		_cool => undef, #Cooler
		_pwr => undef, #Power Connector
		_dvi2 => undef, #Dual-Link DVI Supported
		_hdcp => undef, #HDCP Ready
		_dim => undef, #Card Dimensions
		_feat => undef, #Features
	};
	
	bless $self, $class;
	
	#If we have a hash ref let's go ahead and populate
	$self->__Populate($hashref) if defined($hashref);

	return $self;
}

#PUBLIC PROPERTIES
sub interface 		{ return My::QuickProperty('_iface', @_); }
sub chipManufacturer{ return My::QuickProperty('_chpman', @_); }
sub GPU		 		{ return My::QuickProperty('_gpu', @_); }
sub coreClock 		{ return My::QuickProperty('_coreclk', @_); }
sub shaderClock		{ return My::QuickProperty('_shadeclk', @_); }
sub streamProcessors{ return My::QuickProperty('_procst', @_); }
sub memoryClock		{ return My::QuickProperty('_memclk', @_); }
sub memorySize 		{ return My::QuickProperty('_memsize', @_); }
sub memoryInterface	{ return My::QuickProperty('_memif', @_); }
sub memoryType 		{ return My::QuickProperty('_memtype', @_); }
sub directX 		{ return My::QuickProperty('_dx', @_); }
sub openGL	 		{ return My::QuickProperty('_ogl', @_); }
sub HDMI	 		{ return My::QuickProperty('_hdmi', @_); }
sub DVI		 		{ return My::QuickProperty('_dvi', @_); }
sub VGA		 		{ return My::QuickProperty('_vga', @_); }
sub SLI		 		{ return My::QuickProperty('_sli', @_); }
sub cooler	 		{ return My::QuickProperty('_cool', @_); }
sub powerConnector	{ return My::QuickProperty('_pwr', @_); }
sub dualLinkDVI	 	{ return My::QuickProperty('_dvi2', @_); }
sub HDCP	 		{ return My::QuickProperty('_hdcp', @_); }
sub dimensions 		{ return My::QuickProperty('_dim', @_); }
sub features		{ return My::QuickProperty('_feat', @_); }

#PRIVATE METHOD - Looks through the tech table hash and
#				finds (hopefully) what we need for this obj.
sub __Populate {

	my ($self, $hashref) = @_;
	
	#Set the values
	$self->interface($hashref->{'interface'});
	$self->chipManufacturer($hashref->{'chipset manufacturer'});
	$self->GPU($hashref->{'gpu'});
	$self->coreClock($hashref->{'core clock'});
	$self->shaderClock($hashref->{'shader clock'});
	$self->streamProcessors($hashref->{'stream processors'});
	$self->memoryClock($hashref->{'effective memory clock'});
	$self->memorySize($hashref->{'memory size'});
	$self->memoryInterface($hashref->{'memory interface'});
	$self->memoryType($hashref->{'memory type'});
	$self->directX($hashref->{'directx'});
	$self->openGL($hashref->{'opengl'});
	$self->HDMI($hashref->{'hdmi'});
	$self->DVI($hashref->{'dvi'});
	$self->VGA($hashref->{'vga'});
	$self->SLI($hashref->{'sli support'});
	$self->cooler($hashref->{'cooler'});
	$self->powerConnector($hashref->{'power connector'});
	$self->dualLinkDVI($hashref->{'duallink dvi supported'});
	$self->HDCP($hashref->{'hdcp ready'});
	$self->dimensions($hashref->{'card dimensions'});
	$self->features($hashref->{'features'});
	
	#Create the name
	my $super = $self->{__parent};
	my $name = $super->brand." ".$super->model." ".$self->GPU." ".
				$self->memorySize." ".$self->memoryInterface." ".
				$self->memoryType." ".$self->interface.
				" Video Card";
	$super->name($name);
}

##################################################
##  __   __        ___  __      __        __   __           
## |__) /  \ |  | |__  |__)    /__` |  | |__) |__) |    \ / 
## |    \__/ |/\| |___ |  \    .__/ \__/ |    |    |___  |  
##                                                                          
##################################################
package Component::PowerSupply;

#PUBLIC CONSTRUCTOR - Base constructor for ram object
#				allows population now if we have the hash
sub new {

	#Optional Population
	my ($class, $parent, $hashref) = @_;

	my $self = {
		__parent => $parent,
		_type => undef, #Type
		_maxpwr => undef, #Maximum Power
		_fans => undef, #Fans
		_pfc => undef, #PFC
		_main => undef, #Main Connector
		_12v => undef, #+12V Rails
		_pcie => undef, #PCI-Express Connector
		_sata => undef, #SATA Power Connector
		_sli => undef, #SLI
		_cf => undef, #CrossFire
		_ee => undef, #Energy-Efficient
		_ovp => undef, #Over Voltage Protection
		_involt => undef, #Input Voltage
		_involtran => undef, #Input Frequency Range
		_out => undef, #Output
		_appro => undef, #Approvals
		_dim => undef, #Dimensions
		_lbs => undef, #Weight
		_conn => undef, #Connectors
		_feat => undef, #Features
	};
	
	bless $self, $class;
	
	#If we have a hash ref let's go ahead and populate
	$self->__Populate($hashref) if defined($hashref);

	return $self;
}

#PUBLIC PROPERTIES
sub type	 		{ return My::QuickProperty('_type', @_); }
sub maxPower 		{ return My::QuickProperty('_maxpwr', @_); }
sub fans	 		{ return My::QuickProperty('_fans', @_); }
sub PFC		 		{ return My::QuickProperty('_pfc', @_); }
sub mainConnector	{ return My::QuickProperty('_main', @_); }
sub Volt12Rails		{ return My::QuickProperty('_12v', @_); }
sub PCIeConnector	{ return My::QuickProperty('_pcie', @_); }
sub SATAConnector	{ return My::QuickProperty('_sata', @_); }
sub SLI 			{ return My::QuickProperty('_sli', @_); }
sub crossFire 		{ return My::QuickProperty('_cf', @_); }
sub energyEfficient	{ return My::QuickProperty('_ee', @_); }
sub overVoltProtect	{ return My::QuickProperty('_ovp', @_); }
sub inputVolt 		{ return My::QuickProperty('_involt', @_); }
sub inputFrequency	{ return My::QuickProperty('_involtran', @_); }
sub output			{ return My::QuickProperty('_out', @_); }
sub approvals 		{ return My::QuickProperty('_appro', @_); }
sub dimensions 		{ return My::QuickProperty('_dim', @_); }
sub weight 			{ return My::QuickProperty('_lbs', @_); }
sub connectiors		{ return My::QuickProperty('_conn', @_); }
sub features 		{ return My::QuickProperty('_feat', @_); }

#PRIVATE METHOD - Looks through the tech table hash and
#				finds (hopefully) what we need for this obj.
sub __Populate {

	my ($self, $hashref) = @_;
	
	#Set the values
	$self->maxPower($hashref->{'maximum power'});
	$self->type($hashref->{'type'});
	$self->fans($hashref->{'fans'});
	$self->PFC($hashref->{'pfc'});
	$self->mainConnector($hashref->{'main connector'});
	$self->Volt12Rails($hashref->{'+12v rails'});
	$self->PCIeConnector($hashref->{'pci-express connector'});
	$self->SATAConnector($hashref->{'sata power connector'});
	$self->SLI($hashref->{'sli'});
	$self->crossFire($hashref->{'crossfire'});
	$self->energyEfficient($hashref->{'energy-efficient'});
	$self->overVoltProtect($hashref->{'over voltage protection'});
	$self->inputVolt($hashref->{'input voltage'});
	$self->inputFrequency($hashref->{'input frequency range'});
	$self->output($hashref->{'output'});
	$self->approvals($hashref->{'approvals'});
	$self->dimensions($hashref->{'dimensions'});
	$self->weight($hashref->{'weight'});
	$self->connectiors($hashref->{'connectors'});
	$self->features($hashref->{'features'});
	
	#Create the name
	my $super = $self->{__parent};
	my $name = $super->brand." ".$super->series." ".$super->model." ".
				$self->maxPower." ".$super->type." ".$self->energyEfficient." ".
				"PFC ".$self->PFC;
	$super->name($name);
}


##################################################
#       __  ___       ___  __   __   __        __   __  
# |\/| /  \  |  |__| |__  |__) |__) /  \  /\  |__) |  \ 
# |  | \__/  |  |  | |___ |  \ |__) \__/ /~~\ |  \ |__/ 
#                                                       
##################################################
package Component::Motherboard;

#PUBLIC CONSTRUCTOR - Base constructor for motherboard object
#				allows population now if we have the hash
sub new {
	#Optional Population
	my ($class, $parent, $hashref) = @_;

	my $self = {
		__parent => $parent,
		_cpusocket => undef, #CPU Socket Type
		_cputype => undef, #CPU Type
		_fsb => undef, #Front Side Bus
		_nbridge => undef, #North Bridge
		_sbridge => undef, #South Bridge
		_ramslot => undef, #Number of Memory Slots
		_ramtype => undef, #Memory Standard
		_rammax => undef, #Maximum Memory Supported
		_ramchan => undef, #Channel Supported
		_pciexp2 => undef, #PCI Express 2.0 x16
		_pciexp1 => undef, #PCI Express x1
		_pcislot => undef, #PCI Slots
		_hddpata => undef, #PATA
		_hddsata3 => undef, #SATA 3Gb/s
		_hddsata6 => undef, #SATA 6Gb/s
		_onvideo => undef, #Onboard Video Chipset
		_onaudio => undef, #Audio Channels
		_lanmax => undef, #Max LAN Speed
		_ps2 => undef, #PS/2
		_usb2 => undef, #USB 1.1/2.0
		_usb3 => undef, #USB 3.0
		_ieee1394 => undef, #IEEE 1394
		_audioports => undef, #Audio Ports
		_on1394 => undef, #Onboard 1394
		_form => undef, #Form Factor
		_dimension => undef, #Dimensions
		_pwrpin => undef, #Power Pin
		_features => undef, #Features
		_package => undef, #Package Contents
	};
	
	bless $self, $class;
	
	#If we have a hash ref let's go ahead and populate
	$self->__Populate($hashref) if defined($hashref);

	return $self;
}

#PUBLIC PROPERTIES
sub cpuSocket		{ return My::QuickProperty('_cpusocket', @_); }
sub cpuType			{ return My::QuickProperty('_cputype', @_); }
sub frontSideBus	{ return My::QuickProperty('_fsb', @_); }
sub northBridge		{ return My::QuickProperty('_nbridge', @_); }
sub southBridge 	{ return My::QuickProperty('_sbridge', @_); }
sub memorySlots 	{ return My::QuickProperty('_ramslot', @_); }
sub memoryType 		{ return My::QuickProperty('_ramtype', @_); }
sub memoryMax 		{ return My::QuickProperty('_rammax', @_); }
sub memoryChannel 	{ return My::QuickProperty('_ramchan', @_); }
sub pciExpress2 	{ return My::QuickProperty('_pciexp2', @_); }
sub pciExpress 		{ return My::QuickProperty('_pciexp1', @_); }
sub pciSlots 		{ return My::QuickProperty('_pcislot', @_); }
sub psata 			{ return My::QuickProperty('_hddpata', @_); }
sub sata3 			{ return My::QuickProperty('_hddsata3', @_); }
sub sata6 			{ return My::QuickProperty('_hddsata6', @_); }
sub onBoardVideo 	{ return My::QuickProperty('_onvideo', @_); }
sub onBoardAudio 	{ return My::QuickProperty('_onaudio', @_); }
sub onBoardLAN 		{ return My::QuickProperty('_lanmax', @_); }
sub ps2 			{ return My::QuickProperty('_ps2', @_); }
sub usb2 			{ return My::QuickProperty('_usb2', @_); }
sub usb3 			{ return My::QuickProperty('_usb3', @_); }
sub ieee1394 		{ return My::QuickProperty('_ieee1394', @_); }
sub audioPorts 		{ return My::QuickProperty('_audioports', @_); }
sub onBoard1394 	{ return My::QuickProperty('_on1394', @_); }
sub formFactor 		{ return My::QuickProperty('_form', @_); }
sub dimensions 		{ return My::QuickProperty('_dimension', @_); }
sub powerPin 		{ return My::QuickProperty('_pwrpin', @_); }
sub features 		{ return My::QuickProperty('_features', @_); }
sub packaging 		{ return My::QuickProperty('_package', @_); } 

#PRIVATE METHOD - Looks through the tech table hash and
#				finds (hopefully) what we need for this obj.
sub __Populate {

	my ($self, $hashref) = @_;
	
	#Set the values	
	$self->cpuSocket($hashref->{'cpu socket type'});
	$self->cpuType($hashref->{'cpu type'});
	$self->frontSideBus($hashref->{'fsb'});
	$self->northBridge($hashref->{'north bridge'});
	$self->southBridge($hashref->{'south bridge'});
	$self->memorySlots($hashref->{'number of memory slots'});
	$self->memoryType($hashref->{'memory standard'});
	$self->memoryMax($hashref->{'maximum memory supported'});
	$self->memoryChannel($hashref->{'channel supported'});
	$self->pciExpress2($hashref->{'pci express 2.0 x16'});
	$self->pciExpress($hashref->{'pci express x1'});
	$self->pciSlots($hashref->{'pci slots'});
	$self->psata($hashref->{'pata'});
	$self->sata3($hashref->{'sata 3gb/s'});
	$self->sata6($hashref->{'sata 6gb/s'});
	$self->onBoardVideo($hashref->{'onboard video chipset'});
	$self->onBoardAudio($hashref->{'audio channels'});
	$self->onBoardLAN($hashref->{'max lan speed'});
	$self->ps2($hashref->{'ps/2'});
	$self->usb2($hashref->{'usb 1.1/2.0'});
	$self->usb3($hashref->{'usb 3.0'});
	$self->ieee1394($hashref->{'ieee 1394'});
	$self->audioPorts($hashref->{'audio ports'});
	$self->onBoard1394($hashref->{'onboard 1394'});
	$self->formFactor($hashref->{'form factor'});
	$self->dimensions($hashref->{'dimensions'});
	$self->powerPin($hashref->{'power pin'});
	$self->features($hashref->{'features'});
	$self->packaging($hashref->{'package contents'});
	
	#Create the name
	my $super = $self->{__parent};
	my $name = $super->brand." ".$super->model." ".$self->cpuSocket." ".
				$self->northBridge." ".$self->formFactor;
	$super->name($name);
}

##################################################
##       __   __  
## |__| |  \ |  \ 
## |  | |__/ |__/ 
##               
##################################################

#Internal Hard Drive
package Component::HDD::Internal;

sub new {
	my ($class, $parent, $hashref) = @_;

	my $self = {	
		_cache => $hashref->{'cache'}, #Cache
		_seek => $hashref->{'average seek time'}, #Average Seek Time
		_write => $hashref->{'average write time'}, #Average Write Time
		_latency => $hashref->{'average latency'}, #Average Latency
		_rpm => $hashref->{'rpm'}, #Revolutions Per Minute
	};	
		
	bless $self, $class;
	return $self;
}

sub cache 		{ return My::QuickProperty('_cache', @_); } #Cache
sub seekTime	{ return My::QuickProperty('_seek', @_); } #Average Seek Time
sub writeTime	{ return My::QuickProperty('_write', @_); } #Average Write Time
sub latency		{ return My::QuickProperty('_latency', @_); } #Average Latency
sub rpm 		{ return My::QuickProperty('_rpm', @_); } #Revolutions Per Minute

#Solid State Hard Drive
package Component::HDD::SolidState;

sub new {
	my ($class, $parent, $hashref) = @_;

	my $self = {		
		_shock => $hashref->{'max shock resistance'}, #Max Shock Resistance
		_poweract => $hashref->{'power consumption (active)'}, #Power Consumption (Active)
		_poweridl => $hashref->{'power consumption (idle)'}, #Power Consumption (Idle)
		_seqread => $hashref->{'sequential access - read'}, #Sequential Access - Read
		_seqritte => $hashref->{'sequential access - write'}, #Sequential Access - Write
		_mtbf => $hashref->{'mtbf'}, #Mean time between failures
		_arc => $hashref->{'architecture'}, #Architecture
	};	
		
	bless $self, $class;
	return $self;
}

sub shockResist 			{ return My::QuickProperty('_shock', @_); }
sub powerActive 			{ return My::QuickProperty('_poweract', @_); }
sub powerIdle 				{ return My::QuickProperty('_poweridl', @_); }
sub seqAccessRead 			{ return My::QuickProperty('_seqread', @_); }
sub seqAccessWrite 			{ return My::QuickProperty('_seqritte', @_); }
sub meanTimeBetweenFailures { return My::QuickProperty('_mtbf', @_); }
sub architecture 			{ return My::QuickProperty('_arc', @_); }

#General Hard Drive
package Component::HDD;

#PUBLIC CONSTRUCTOR - Base constructor for hard drive object
#				allows population now if we have the hash
sub new {

	#Optional Population
	my ($class, $parent, $hashref) = @_;

	my $self = {
		__parent => $parent,
		_face => undef, #Interface
		_size => undef, #Capacity
		_form => undef, #Form Factor
		_feature => undef, #Features
		_specific => undef,#Specific features to Internal, or SSD
	
	};
	
	bless $self, $class;
	
	#If we have a hash ref let's go ahead and populate
	$self->__Populate($hashref) if defined($hashref);

	return $self;
}

#PUBLIC PROPERTIES
sub interface 		{ return My::QuickProperty('_face', @_); }
sub size	 		{ return My::QuickProperty('_size', @_); }
sub formFactor		{ return My::QuickProperty('_form', @_); }
sub features 		{ return My::QuickProperty('_feature', @_); }

#PRIVATE METHOD - Looks through the tech table hash and
#				finds (hopefully) what we need for this obj.
sub __Populate {

	my ($self, $hashref) = @_;
	
	#Set the values
	$self->interface($hashref->{'interface'});
	$self->interface($hashref->{'interface type'});
	$self->size($hashref->{'capacity'});
	$self->formFactor($hashref->{'form factor'});	
	$self->features($hashref->{'features'});
	
	#Internal or Solid state?
	my ($child, $name);
	my $parent = $self->{__parent};	
	given($parent->{_nav}->{_sub}) {
		when(My::SUB_HDD_SSD) {
			$child = new Component::HDD::SolidState($self, $hashref);
			$name = $parent->brand." ".$parent->series." ".$parent->model." ".
					$self->formFactor." ".$self->size." ".$child->architecture;
		}
		when(My::SUB_HDD_INT) {
			$child = new Component::HDD::Internal($self, $hashref);
			$name = $parent->brand." ".$parent->series." ".$parent->model." ".
					$self->size." ".$child->rpm." ".$child->cache." ".$self->interface;
		}
	}
	
	#Set the child object and name
	$self->{_specific} = $child;
	$parent->name($name);
}


##################################################
##  __             
## |__)  /\   |\/| 
## |  \ /~~\  |  | 
##                 
##################################################
package Component::RAM;

#PUBLIC CONSTRUCTOR - Base constructor for ram object
#				allows population now if we have the hash
sub new {

	#Optional Population
	my ($class, $parent, $hashref) = @_;

	my $self = {
		__parent => $parent,
		_size => undef, #Capacity
		_speed => undef, #Speed
		_cas => undef, #Cas Latency
		_time => undef, #Timing
		_volt => undef, #Voltage
		_channel => undef,#Multi-channel Kit
		_heat => undef, #Heat Spreader
		_feature => undef, #Features
		_uses => undef, #Recommend Use
		_ecc => undef, #ECC
		_buff => undef, #Buffered/Registered
	};
	
	bless $self, $class;
	
	#If we have a hash ref let's go ahead and populate
	$self->__Populate($hashref) if defined($hashref);

	return $self;
}

#PUBLIC PROPERTIES
sub capacity 		{ return My::QuickProperty('_size', @_); }
sub speed 			{ return My::QuickProperty('_speed', @_); }
sub casLatency 		{ return My::QuickProperty('_cas', @_); }
sub timing 			{ return My::QuickProperty('_time', @_); }
sub voltage 		{ return My::QuickProperty('_volt', @_); }
sub channel 		{ return My::QuickProperty('_channel', @_); }
sub heatSpreader 	{ return My::QuickProperty('_heat', @_); }
sub features		{ return My::QuickProperty('_feature', @_); }
sub uses	 		{ return My::QuickProperty('_uses', @_); }
sub errorcc 		{ return My::QuickProperty('_ecc', @_); }
sub buffReg 		{ return My::QuickProperty('_buff', @_); }

#PRIVATE METHOD - Looks through the tech table hash and
#				finds (hopefully) what we need for this obj.
sub __Populate {

	my ($self, $hashref) = @_;
	
	#Set the values
	$self->capacity($hashref->{'capacity'});
	$self->speed($hashref->{'speed'});
	$self->casLatency($hashref->{'cas latency'});
	$self->timing($hashref->{'timing'});
	$self->voltage($hashref->{'voltage'});
	$self->channel($hashref->{'multi-channel kit'});
	$self->heatSpreader($hashref->{'heat spreader'});
	$self->features($hashref->{'features'});
	$self->uses($hashref->{'recommend use'});
	$self->errorcc($hashref->{'ecc'});
	$self->buffReg($hashref->{'buffered/registered'});
	
	#Create the name
	my $super = $self->{__parent};
	my $name = $super->brand." ".$self->capacity." ".$super->type." ".
				$self->speed." ".$self->channel." Model ".$super->model;
	$super->name($name);
}

##################################################
##  __   __       
## /  ` |__) |  | 
## \__, |    \__/ 
##                
##################################################
package Component::CPU;

#PUBLIC CONSTRUCTOR - Base constructor for cpu object
#				allows population now if we have the hash
sub new {

	#Optional Population
	my ($class, $parent, $hashref) = @_;

	my $self = {
		__parent => $parent,
		_socket => undef, #CPU Socket Type
		_core => undef, #Core
		_multi => undef, #Multi-Core
		_speed => undef, #Operating Frequency
		_qpi => undef, #QPI
		_l2 => undef, #L2 Cache
		_l3 => undef, #L3 Cache
		_tech => undef, #Manufacturing Tech
		_64bit => undef, #64 bit Support
		_ht => undef, #Hyper-Threading Support
		_vts => undef, #Virtualization Technology Support
		_volt => undef, #Voltage
		_therm => undef, #Thermal Design Power
		_cool => undef, #Cooling Device
	};
	
	bless $self, $class;
	
	#If we have a hash ref let's go ahead and populate
	$self->__Populate($hashref) if defined($hashref);

	return $self;
}

#PUBLIC PROPERTIES
sub socket	 		{ return My::QuickProperty('_socket', @_); }
sub core 			{ return My::QuickProperty('_core', @_); }
sub multi	 		{ return My::QuickProperty('_multi', @_); }
sub speed 			{ return My::QuickProperty('_speed', @_); }
sub qpi		 		{ return My::QuickProperty('_qpi', @_); }
sub l2cache 		{ return My::QuickProperty('_l2', @_); }
sub l3cache		 	{ return My::QuickProperty('_l3', @_); }
sub tech			{ return My::QuickProperty('_tech', @_); }
sub bit64	 		{ return My::QuickProperty('_64bit', @_); }
sub hyperthreading	{ return My::QuickProperty('_ht', @_); }
sub virtualtechsup	{ return My::QuickProperty('_vts', @_); }
sub voltage	 		{ return My::QuickProperty('_volt', @_); }
sub power			{ return My::QuickProperty('_therm', @_); }
sub cooling 		{ return My::QuickProperty('_cool', @_); }
sub name 			{ return My::QuickProperty('_name', @_); }

#PRIVATE METHOD - Looks through the tech table hash and
#				finds (hopefully) what we need for this obj.
sub __Populate {

	my ($self, $hashref) = @_;

	#Set the values	
	$self->socket($hashref->{'cpu socket type'});
	$self->core($hashref->{'core'});
	$self->multi($hashref->{'multi-core'});
	$self->speed($hashref->{'operating frequency'});
	$self->qpi($hashref->{'qpi'});
	$self->l2cache($hashref->{'l2 cache'});
	$self->l3cache($hashref->{'l3 cache'});
	$self->tech($hashref->{'manufacturing tech'});
	$self->bit64($hashref->{'64 bit support'});
	$self->hyperthreading($hashref->{'hyper-threading support'});
	$self->virtualtechsup($hashref->{'virtualization technology support'});
	$self->voltage($hashref->{'voltage'});
	$self->power($hashref->{'thermal design power'});
	$self->cooling($hashref->{'cooling device'});
	$self->name($hashref->{'name'});
	
	#Create the name
	my $super = $self->{__parent};
	my $name = $super->brand." ".$self->name." ".$self->core." ".
				$self->speed." ".$self->l3cache." ".$self->socket." ".
				$self->power." ".$self->multi." ".$super->model;
	$super->name($name);	
}

package Component::Performance;

#PUBLIC CONSTRUCTOR - Base constructor for performance object
sub new {
	my ($class, $parent) = @_;
	
	my $self = {
		__parent => $parent,
		_name => '',
		_page => '',
		_score => '',
	};
	
	bless $self, $class;
	return $self;	
}

#PUBLIC PROPERTIES
sub page { return My::QuickProperty('_page', @_); }
sub score { return My::QuickProperty('_score', @_); }
sub name { return My::QuickProperty('_name', @_); }

sub ticklePassMark {
	my ($self) = @_;
	my $parent = $self->{__parent};
	
	#Get the group of the component
	my $group = $parent->component();
	
	#Get the proper page and name
	my $final = '';
	given($group){

		#CPUs
		when(/cpu/) {
			$self->page("http://www.cpubenchmark.net/high_end_cpus.html");
			
			#Get the brand
			my $brand = $parent->brand;
			
			#Remove Excess Info from the name
			my $specs = $parent->{_specs};
			my $name = $specs->name;
			$name =~ s/ Extreme Edition//gi;
			$name =~ s/-/ /;
			
			#Get speed
			my $speed = $specs->speed;
			
			#Save the name in PassMark format
			$final = ($brand." ".$name." \@ ".$speed);
		}

		#Doesn't have a rating
		default{ return undef;}
	}
	#save it
	$self->name($final);
	
	#Fetch the page content
	#my $html = LWP::Simple::get $self->page or die "Net esplode";
	my $html;
	
	#Split the HTML into usable lines
	my @lines = split(/\n|\t/, $html);

	#Extract the line which has the score
	my @find = grep(/$final/i, @lines);
	
	#REmove html
	my $score = My::NoHTML($find[0]);
	chomp $score;
	$score =~ s/$final//g; #Remove our own name
	$score =~ s/\D//g; #Remove commas
	
	
	$self->score($score);
}

##################################################
##  __   __         __   __        ___      ___ 
## /  ` /  \  |\/| |__) /  \ |\ | |__  |\ |  |
## \__, \__/  |  | |    \__/ | \| |___ | \|  |                                               
##
##################################################
package Component;

my $BASE = 'http://www.newegg.com/Product/Product.aspx?Item=';
my $PRICE = 'http://www.newegg.com/Product/MappingPrice.aspx?Item=';

#PUBLIC CONSTRUCTOR - Base constructor for component object
sub new {

	my ($class) = @_;

	my $self = {
		_name => '',
		_brand => '',
		_series => '',
		_model => '',
		_type => '',
		_price => undef,
		_nen => undef, #NewEgg Number
		_nav => undef, #Navigation tree (Cat, Sub, Brand)
	};
	bless $self, $class;
	return $self;
}

#Saves a component to the database
sub loadDB {
	my ($self, $dbh) = @_;
	
	#Do we connect to the sql server?
	my $weSQL;	
	defined($dbh) ? $weSQL = 0 : $weSQL = 1;
	$dbh = My::SqlConnect if $weSQL;
	
	#Insert new or update price
	my $SQL = "SELECT name, price, brand_key, component_key) ".
			  "FROM product p WHERE p.nen=?";
	
	# form up the query
	my $sth = $dbh->prepare($SQL) or warn "Unable to prepare <<$SQL>>";
	$sth->execute($self->newEggNum)  or warn "Unable to execute <<$SQL>>";

	if(my $Row=$sth->fetchrow_hashref()){
			$self->name($Row->{name});
			$self->price($Row->{price});
			$self->{_nav}->{_bran} = $Row->{brand_key};
			#$self->name($Row->{component_key});
		}

	
	#IF we connected, disconenct
	$sth->finish();
	$dbh->disconnect() if $weSQL;
	
	return $self;
}

#Saves a component to the database
sub saveDB {
	my ($self, $dbh) = @_;
	
	#Do we connect to the sql server?
	my $weSQL;	
	defined($dbh) ? $weSQL = 0 : $weSQL = 1;
	$dbh = My::SqlConnect if $weSQL;
	
	#Insert new or update price
	my $SQL = "INSERT INTO product (nen, name, price, brand_key, component_key) ".
			  "VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE price=?";
	
	#Prepare the values to be inserted
	my @values = ($self->newEggNum, $self->name, $self->price, $self->{_nav}->{_bran}, '0', $self->price);

	my $sth = $dbh->prepare($SQL) or warn "Unable to prepare <<$SQL>>";
	$sth->execute(@values) or warn "Unable to execute <<$SQL>>";	
	
	#IF we connected, disconenct
	$sth->finish();
	$dbh->disconnect() if $weSQL;
}

#PUBLIC PRINT - Description for component object
sub print {
	my ($self) = @_;
	
	#Print info
	printf("Item: %s \nPrice: %s\nNE#: %s\n",
		$self->name,
		$self->price,
		$self->newEggNum);
}

#PUBLIC PROPERTY - Brand of the component object
sub brand {
    my ( $self, $brand ) = @_;
    $self->{_brand} = $brand if defined($brand);
    return $self->{_brand};
}

#PUBLIC PROPERTY - Series of the component object
sub series {
    my ( $self, $series ) = @_;
    $self->{_series} = $series if defined($series);
    return $self->{_series};
}

#PUBLIC PROPERTY - Model of the component object
sub model {
    my ( $self, $model ) = @_;
    $self->{_model} = $model if defined($model);
    return $self->{_model};
}

#PUBLIC PROPERTY - Type of the component object
sub type {
    my ( $self, $type ) = @_;
    $self->{_type} = $type if defined($type);
    return $self->{_type};
}

#PUBLIC PROPERTY - Price of the component object
sub price {
    my ( $self, $price ) = @_;
    $self->{_price} = $price if defined($price);
    return $self->{_price};
}

#PUBLIC PROPERTY - NewEgg Number of the component object
sub newEggNum {
    my ( $self, $nen ) = @_;
    $self->{_nen} = $nen if defined($nen);
    return $self->{_nen};
}

#PUBLIC PROPERTY - Name of the component object
sub name {
    my ( $self, $name ) = @_;
    $self->{_name} = $name if defined($name);
    return $self->{_name};
}

sub score {
	my $self = shift;
	my $score = $self->{_perform}->score;
	$score ? return $score : return undef;
}

#PUBLIC METHOD - Gets the subclassification of the component
#				by looking at the directory structure and making
#				a best guess as to what it is.
sub component {
	my ($self) = @_;
	
	#Get the navigations
	my $cat = scalar($self->{_nav}->{_cat});
	my $sub = scalar($self->{_nav}->{_sub});
	my $bran = scalar($self->{_nav}->{_bran});
	
	#Depending on the directory, which component subtype?
	my $type = '';
	
	#Category
	given($cat) {
		when(My::CAT_MOBO)	{$type = "mobo";}
		when(My::CAT_POWER)	{$type = "power";}
		when(My::CAT_CPU)	{$type = "cpu";}
		when(My::CAT_VID)	{$type = "video";}
	}
	
	#Subcategory
	given($sub) {	
		when (My::SUB_HDD_INT) 		{$type = "hdd";} #14 - Internal Hard Drives
		#when (My::SUB_MOBO_AMD)	{$type = "mobo";}#22 - AMD Motherboards
		when (My::SUB_RAM) 			{$type = "ram";} #147 - Desktop Memory
		#when (My::SUB_MOBO_INTEL)	{$type = "mobo";}#280 - AMD Motherboards
		when (My::SUB_CPU) 			{$type = "cpu";} #343 - Processors - Desktops
		when (My::SUB_HDD_SSD) 		{$type = "hdd";} #636 - SSD
	}
	
	return $type
}

#PUBLIC METHOD - Goes to PassMark and gets relevant performance info
sub ticklePassMark {
	my ($self) = @_;
	
	#Create performance object
	$self->{_perform} = new Component::Performance($self);
	
	#Get the relevant data
	$self->{_perform}->ticklePassMark;
}

#PUBLIC METHOD - Goes to NewEgg and gets all the relevant data
sub tickleNewEgg {

	#Get the Part ID;
	my ($self) = @_;

	#Fetch the page content
	my $url = $BASE.$self->newEggNum;
	my $mech = WWW::Mechanize->new() or die "Net esplode";
	
	my $response = $mech->get($url);
	my $html = $response->decoded_content();	
	
	#Remove line flushes, as that seriously fucks up shit
	$html =~ s/\r//g;
	
	#Split the HTML into usable lines
	my @lines = split(/\n|\t/, $html);
	
	#Parse the categories
	$self->__GetNavigation(\@lines);
	
	#Parse the specs
	my @specs = grep(/specTitle/, @lines); 
	my $Info = __ParseDataTable(\@specs);
	
	#Assign general specs
	$self->brand($Info->{'brand'});
	$self->series($Info->{'series'});
	$self->model($Info->{'model'});
	$self->type($Info->{'type'});
	$self->type($Info->{'device type'});
	
	#Assign the specific spec
	$self->__GetComponentSubClass($Info);
	
	#Finally, get the price from a differnt page.
	$url = $PRICE.$self->newEggNum;
	$response = $mech->get($url);
	$html = $response->decoded_content();
	@lines = split(/\n/, $html);
	
	$self->price(__GetPrice(\@lines));
}

#PRIVATE METHOD - Gets the subclassification of the component
#				and creates the appropiate subclass object
sub __GetComponentSubClass {
	my ($self, $hashref) = @_;
	
	my $sub;
	
	#Create the different Object and populate
	given($self->component()) {
		when(/cpu/)  {$sub = new Component::CPU($self, $hashref);}
		when(/ram/)  {$sub = new Component::RAM($self, $hashref);}
		when(/hdd/)  {$sub = new Component::HDD($self, $hashref);}
		when(/mobo/) {$sub = new Component::Motherboard($self, $hashref);}
		when(/power/) {$sub = new Component::PowerSupply($self, $hashref);}
		when(/video/) {$sub = new Component::VideoCard($self, $hashref);}
	}
	
	#Save it
	$self->{_specs} = $sub;
}

#PRIVATE METHOD - Parses through the HTML to find the category,
#				subcategory, and brand of an item using NewEgg's
#				numbering system.
sub __GetNavigation {

	#Get the lines
	my ($self, $linesref) = @_;
	my @lines = @$linesref;
	
	my %Info;
	
	#Looping for each line, find the data lable, title, and data	
	my $start = 0;
	foreach my $line(@lines) {		
		
		if($line =~ m/SubCategory=(\d+)/) {
			$self->{_nav}->{_sub} = $1;
		}
	}

}

#PRIVATE METHOD - Parses through the HTML to find the
#				Technical Specifications of the product
#				it puts all the data into a hash which
#				is sorted out later by other method.
sub __ParseDataTable() {

	#Get the lines
	my $linesref = shift;
	my @lines = @$linesref;
	
	#Read each line, saving useful ones.
	my %Info;
	
	#Looping for each line, find the data lable, title, and data	
	foreach my $line(@lines) {
		while($line =~ m!<dl><dt>([^<]+)</dt><dd>([^<]+)</dd></dl>!g) {
			my $key = My::NoSpace(My::NoHTML(lc($1)));
			my $val = My::NoSpace($2);
			$Info{$key} = $val;
		}
	}
	
	#Return that hash
	return \%Info;
}

#PRIVATE METHOD - Parses through the HTML and gets
#				the price of the item.
sub __GetPrice() {

	#Get the lines
	my $linesref = shift;
	my @lines = @$linesref;

	#Extract the line which has the price
	foreach my $line(@lines) {
	
		$line =~ s/[\t\r]//g;	
		while($line =~ m!\$(\d+\.\d{2})!m) {
			return $1;
		}
	}
        
	#Return the price
	return undef;
}

1;
__END__
