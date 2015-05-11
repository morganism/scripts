#!/usr/bin/perl

################################################################################
# Reading BAF format
# 
# Adam Gutteridge
# Cartesian ltd. 2005
################################################################################



################################################################################
# Set up Variables
################################################################################

my $blockSize = 2048;
my $blockCounter = 1;



################################################################################
# Usage string to display
################################################################################
my $usage = 
"Usage:\n\tprocessSwitchData -i <input file dir> -o <output file dir>]";

################################################################################
# Get the year
###############################################################################
($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
 $year = 1900 + $yearOffset;


################################################################################
#if there are no arguments
################################################################################
if (!$ARGV[0]) 
{
  die("\n$usage\n\n");
}



################################################################################
# Process the command line arguments
################################################################################

while (scalar(@ARGV) > 1)
{
  if ($ARGV[0] eq '-i')
  {
    shift @ARGV;
    $inputFileDir = $ARGV[0];
    shift @ARGV;
  }
  elsif ($ARGV[0] eq '-o')
  {
    shift @ARGV;
    $outputFileDir = $ARGV[0];
    shift @ARGV;
  }
}
opendir (my $dh, $inputFileDir) || die "Can't open input directory : $inputFileDir\n";
my @files = grep {/AMA/}  readdir($dh);
foreach my $f (@files)
{
	print "FN[$f]\n";
}
foreach $f (@files)
{
	if(-e $f)
	{
		print "Processing File $f\n";
		&readFile($f);
	}
	else
	{
		print "'$f' does not exist, check path and file name\n";
	}
}


#################################################################
# Process each file
#################################################################
sub readFile
{
  
	################################################################################
	# Set up variables 
	################################################################################
	$filename = $_[0]; 
	$inputFile = "$inputFileDir/$filename";
	$outputFile = "$outputFileDir/$filename.csv";
	$generatorFile = "$outputFileDir/$filename.cdrGen";
        $logFileDir = "$outputFileDir";
	$logFile = "$logFileDir/$filename.log";




	################################################################################
	# Open Input and Output files 
	################################################################################
	open(IN, $inputFile) || die("\nFailed to open '$inputFile': $!\n\n");
	open(OUT, ">$outputFile") || die("\nFailed to open '$outputFile': $!\n\n");
	open(CDR, ">$generatorFile") || die("\nFailed to open '$outputFile': $!\n\n");
	open(LOG, ">$logFile") || die("\nFailed to open '$logFile': $!\n\n");

	## initialise the output file
        writeOut( "StructureCode, CallTypeCode, SensorType, SensorIdentification, RecordingOfficeType, RecordingOfficeIdentification, Date, TimingIndicator, StudyIndicator, CalledPartyOffHook, ServiceObservedTrafficSampled, OperatorAction, ServiceFeature, SignificantDigitsInNextField, OriginatingOpenDigits1, OriginatingOpenDigits2, OriginatingChargeInformation, DomesticInternationalIndicator, SignificantDigitsInNextField, First15digitsofCalledPartyNumber, Digits16to30ofCalledPartyNumber, ConnectTime, ElapsedTime, CompletionIndicator, module42CallRecordSequence, module22PresentDate, module22PresentTime, module25CircuitReleaseDate, module25CircuitReleaseTime, module70BearerCapabilities, module70NetworkInterworking, module70SignalingorSupplementaryServiceCapabilitiesUse, module70ReleaseCauseIndicator, module71BearerCapabilities, module71NetworkInterworking, module71ReleaseCauseIndicator, module98CarrierConnectDate, module98CarrierConnectTime, module98MessageDirection, module104OutgoingTrunkIdentificationNumber, module104IncomingTrunkIdentificationNumber, module120CustomerGroupIdentification, module130FacilityReleaseCause, module130CallCharacteristic,module260Start, module260End, module509start, module509end, module611Genericcontextidentifier, module611Digitsstring, module612Genericcontextidentifier, module612Genericdigitsstring1, module612Genericdigitsstring2 " ); 

        ## initialise the CDRFile
	writeGenOut( "structure_code,call_type,sensor_identifier,date,timing_indicator_guard,timing_indicator_short_off_hook,study_indicator_SLUS,study_indicator_complaint,study_indicator_study_gen,study_indicator_test_call,study_indicator_missing_num,called_party_off_hook,service_observed,service_feature,a_number,b_number,originating_charge_info,connect_time,elapse_time,call_completion_reason,vpn_dialed_digits,vpn_NPA_NXX ,soc_0,soc_1,soc_2,soc_3,soc_4,soc_5,soc_6,isdn_network_interworking,isdn_CCITT_standard,isdn_release_cause,isdn_bearer_data_type,isdn_bearer_capabilities,isdn_calling_number_CNI,isdn_calling_party_subaddress,isdn_called_party_subaddress,isdn_low_layer_compatability,isdn_high_layer_compatability,isdn_user_to_user_info,isdn_auto_callback_activation,isdn_auto_callback_resolution,isdn_flexible_calling,incoming_trunk_group,incoming_trunk_member,outgoing_trunk_group,outgoing_trunk_member,pre_change_time,pre_change_date,post_change_time,post_change_date,npi_protocol_ID,npi_number_ID,npi_captured_NPI,npi_captured_NOA_or_TON,npi_captured_PI,feature_context_default,feature_service_identifier,feature_service_event,originating_feature_code, terminating_feature_code");


	################################################################################
	# Read Each CDR
	################################################################################

	# Read first 2 bytes which contain total block size 
	while (sysread(IN, $buffer, 2) != 0)
  {
		$usefulBlockSize=unpack("n",$buffer);
    logger("=======================================================");
		logger("Useful size of block = $usefulBlockSize");

		################################################################################
    # Cope with Header Block
		################################################################################


    # Read in Size of block
		sysread(IN, $buffer, 2) || die("\nCannot read from input file.\n\n");


#### The sample AMA record indiates that there are no block headers. 

		#sysread(IN, $buffer, 2) || die("\nCannot read from input file.\n\n");

    $totalBytesUsed=4;

    #$blockHeaderSize=unpack("n",$buffer);
    #logger("Block Header size = $blockHeaderSize");

    #$totalBytesUsed+=$blockHeaderSize;

#		sysread(IN, $buffer, ($blockHeaderSize-2)) || die("\nCannot read from input file.\n\n");
    logger("After block header total used = $totalBytesUsed"); 
    logger("=======================================================");

    # Reset CDR counters
    $cdrInBlockCount=0;


    ####################################
    # Read CDRs
    ####################################
    while($totalBytesUsed < $usefulBlockSize) 
    {
      # Get CDR Size
		  sysread(IN, $buffer, 2) || die("\n1. Cannot read from input file.\n\n");
      $cdrSize=unpack("n",$buffer);
      $totalBytesUsed+=$cdrSize;
      logger("CDR size = $cdrSize");

     
      # Determine CDR Structure Code First
      sysread(IN, $buffer, 3) || die("\n2. Cannot read from input file.\n\n");

      # read in Field 0 Structure Code
      sysread(IN, $buffer, 3) || die("\n2. Cannot read from input file.\n\n");

      $structureCodeStart=unpack("H1",$buffer);

      $structureCode=unpack("H6",$buffer);

      $structureCode=substr($structureCode,1,5);
      $structureCode=~s/c//;
      $structureCode=~s/^0+//;

      logger("Structure structureCode = $structureCode");

  
      # Read remain of CDR into a raw hex String 
      $cdrSize-=8;
      sysread(IN, $buffer, $cdrSize);
      $hexSize=($cdrSize*2);
      $rawString=unpack("H$hexSize",$buffer);

      if ($structureCodeStart == 4 ) 
      {
        logger("modules present (4)");
	if ( $structureCode = 514 ) 
	{
	$mainRecord = substr($rawString,0,148);
	$modules = substr($rawString,148);
	logger("main Records =  $mainRecord");
	logger("modules =  $modules");
        logger("CDR =  $rawString");
        structureCode514($rawString);
	}
	else
	{   
        logger("CDR =  $rawString");
	}
      }
      else 
      {  
        logger(" no modules (0) ");
        logger("CDR =  $rawString");
      }

      #############################################
      # Process CDR depending on Structure Code
      #############################################

      ### Check if start of file is normal
      ##if ($blockCounter == 1 and $structureCode != 7)      
      ##{
        ##logger("Invalid Start of block, file rejected"); 
        ### Maybe a reject file routine here?
      ##}
      ##if ($structureCode == 8 ) 
      ##{
        ### End of File
        ##logger("\n\n##############################");
        ##logger("End of File found\n");
        ##logger("##############################\n");
        ### Maybe a end of file routine here?
      ##}
      ##elsif ($structureCode == 2) 
      ##{
        ### Mobile Originating Call Attempt
        ##stuctureCode2($rawString);
      ##}
      ##elsif ($structureCode == 3)
      ##{
        ### Mobile Terminated Call Attempt
        ##stuctureCode3($rawString);
      ##}
      ##elsif ($structureCode == 4)
      ##{
        ##my $outputString = moduleCodeReader(substr($rawString,220));
      ##}
      ##elsif ($structureCode == 5)
      ##{
        ##my $outputString = moduleCodeReader(substr($rawString,224));
      ##}
      ##elsif ($structureCode == 15)
      ##{
        ##my $outputString = moduleCodeReader(substr($rawString,234));
      ##}
      ##elsif ($structureCode == 16)
      ##{
        ##my $outputString = moduleCodeReader(substr($rawString,234));
      ##}
      ##elsif ($structureCode == 18)
      ##{
        ##my $outputString = moduleCodeReader(substr($rawString,314));
      ##}


      # Update Counters
      $cdrInBlockCount++;
      $cdrTotalCount++;
    }

    ##########################################################
    # Skip remaining rest of block if it not all used
    ##########################################################
    if ($totalBytesUsed < $blockSize)
    {
      $remainingBlock=($blockSize-$usefulBlockSize);
      sysread(IN, $buffer, $remainingBlock) || die("\n4. Cannot read from input file.\n\n");
    }

    logger("CDRs in block = $cdrInBlockCount");

    $blockCounter++;
	}
    logger("Total number of CDRs    = $cdrTotalCount");
    logger("Total number of blocks  = $blockCounter");
}


###############################################################################
# STRUCTURE CODES SECTION                                                      
###############################################################################




#######################################################
# Structure Code 2 - Mobile Originated Call Attempt
#######################################################
sub stuctureCode2
{
  my ($inputString)=@_;

  # Set fields
  my $StudyIndicator = substr($inputString,4,2);
  my $CallforwardIndicator = substr($inputString,6,2);
  my $CallingParty = substr($inputString,8,30);
  my $CallingNumber = substr($inputString,38,30);
  my $CalledNumber = substr($inputString,68,40);
  my $CallingEquipment = substr($inputString,108,22);
  my $AdditionalInformation = substr($inputString,130,4);
  my $ChannelAllocationTime = substr($inputString,134,16);
  my $AnswerTime = substr($inputString,150,16);
  my $DisconnectTime = substr($inputString,166,16);
  my $ReleaseTime = substr($inputString,182,16);
  my $OffAirCallSetup = substr($inputString,198,2);
  my $HalfRateinUse = substr($inputString,200,2);
  my $CauseforTermination = substr($inputString,202,4);
  my $CallReference = substr($inputString,206,8);
  my $MSClassmark = substr($inputString,214,8);
  my $ClassmarkTimeStamp = substr($inputString,222,16);
  my $DialledDigits = substr($inputString,238,34);
  my $OutgoingTrunkGroup = substr($inputString,272,6);
  my $OutgoingTrunkMember = substr($inputString,278,6);
  my $OutgoingRouteGroup = substr($inputString,284,4);
  my $TrunkSeizureOutgoing = substr($inputString,288,16);
  my $CallingSubscriberCategory = substr($inputString,304,4);
  my $CallIndicator = substr($inputString,308,8);
  my $CallDuration = substr($inputString,316,8);
  my $Diagnostic = substr($inputString,324,6);
  my $MSCNumber = substr($inputString,330,28);
  my $RecordNumber = substr($inputString,358,12);


  
$moduleOutput = moduleCodeReader(substr($inputString,370));
  # Write Out CDR to output file
  my $outputString = join (',', 
  $structureCode, 
  $StudyIndicator ,$CallforwardIndicator , $CallingParty,
  $CallingNumber, $CalledNumber, $CallingEquipment, 
  $AdditionalInformation, $ChannelAllocationTime, $AnswerTime, 
  $DisconnectTime, $ReleaseTime, $OffAirCallSetup, 
  $HalfRateinUse, $CauseforTermination, $CallReference,
  $MSClassmark, $ClassmarkTimeStamp, $DialledDigits, 
  $OutgoingTrunkGroup, $OutgoingTrunkMember, $OutgoingRouteGroup, 
  $TrunkSeizureOutgoing, $CallingSubscriberCategory, $CallIndicator, 
  $CallDuration, $Diagnostic, $MSCNumber, 
  $RecordNumber);

  writeOut("$outputString");
  return;
}



#######################################################
# Structure Code 3 - Mobile Terminated Call Attempt
#######################################################
sub stuctureCode3
{
  my ($inputString)=@_;

  # Set fields
  my $StudyIndicator = substr($inputString,4,2);
  my $CallforwardIndicator = substr($inputString,6,2);
  my $CalledParty = substr($inputString,8,30);
  my $CallingNumber = substr($inputString,38,30);
  my $CalledNumber = substr($inputString,68,40);
  my $CalledEquipment = substr($inputString,108,22);
  my $AdditionalInformation = substr($inputString,130,4);
  my $ChannelAllocationTime = substr($inputString,134,16);
  my $AnswerTime = substr($inputString,150,16);
  my $DisconnectTime = substr($inputString,166,16);
  my $ReleaseTime = substr($inputString,182,16);
  my $OffAirCallSetup = substr($inputString,198,2);
  my $HalfRateinUse = substr($inputString,200,2);
  my $CauseforTermination = substr($inputString,202,4);
  my $CallReference = substr($inputString,206,8);
  my $MSClassmark = substr($inputString,214,8);
  my $ClassmarkTimeStamp = substr($inputString,222,16);
  my $IncomingTrunkGroup = substr($inputString,238,6);
  my $IncomingTrunkMember = substr($inputString,244,6);
  my $IncomingRouteGroup = substr($inputString,250,4);
  my $TrunkSeizureIncoming = substr($inputString,254,16);
  my $CalledSubscriberCategory = substr($inputString,270,4);
  my $CallIndicator = substr($inputString,274,8);
  my $CallDuration = substr($inputString,282,8);
  my $Diagnostic = substr($inputString,290,6);
  my $MSCNumber = substr($inputString,296,28);
  my $RecordNumber = substr($inputString,324,12); 

   $moduleOutput = moduleCodeReader(substr($inputString,336));

  # Write Out CDR to output file
  my $outputString = join (',', 
  $structureCode, 
  $StudyIndicator ,$CallforwardIndicator , $CalledParty,
  $CallingNumber, $CalledNumber, $CalledEquipment, 
  $AdditionalInformation, $ChannelAllocationTime, $AnswerTime, 
  $DisconnectTime, $ReleaseTime, $OffAirCallSetup, 
  $HalfRateinUse, $CauseforTermination, $CallReference,
  $MSClassmark, $ClassmarkTimeStamp, 
  $IncomingTrunkGroup, $IncomingTrunkMember, $IncomingRouteGroup, $TrunkSeizureIncoming, 
  $CallingSubscriberCategory, $CallIndicator, 
  $CallDuration, $Diagnostic, $MSCNumber, 
  $RecordNumber , $moduleOutput);

  writeOut("$outputString");
  return;
}


##########################################################################
# Structure Code 514  - 
#########################################################################
sub structureCode514
{ 
   my ($inputString)=@_;
   # Set fields 
   my $CallTypeCode = substr($inputString,0, 4);  $CallTypeCode=~s/c// ;
   my $SensorType = substr($inputString,4, 4);  $SensorType=~s/c// ;
   my $SensorIdentification = substr($inputString,8, 8);  $SensorIdentification=~s/c// ;
   my $RecordingOfficeType = substr($inputString,16, 4);  $RecordingOfficeType=~s/c// ;
   my $RecordingOfficeIdentification = substr($inputString,20, 8);  $RecordingOfficeIdentification=~s/c// ;
   my $Date = substr($inputString,28, 6);  $Date=~s/c// ;
   my $TimingIndicator = substr($inputString,34, 6);  $TimingIndicator=~s/c// ;
   my $StudyIndicator = substr($inputString,40, 8);  $StudyIndicator=~s/c// ;
   my $CalledPartyOffHook = substr($inputString,48, 2);  $CalledPartyOffHook=~s/c// ;
   my $ServiceObservedTrafficSampled = substr($inputString,50, 2);  $ServiceObservedTrafficSampled=~s/c// ;
   my $OperatorAction = substr($inputString,52, 2);  $OperatorAction=~s/c// ;
   my $ServiceFeature = substr($inputString,54, 4);  $ServiceFeature=~s/c// ;
   my $callingSignificantDigitsInNextField = substr($inputString,58, 4);  $callingSignificantDigitsInNextField=~s/c// ;
   my $OriginatingOpenDigits1 = substr($inputString,62, 12);  $OriginatingOpenDigits1=~s/c// ;
   my $OriginatingOpenDigits2 = substr($inputString,74, 10);  $OriginatingOpenDigits2=~s/c// ;
   my $OriginatingChargeInformation = substr($inputString,84, 4);  $OriginatingChargeInformation=~s/c// ;
   my $DomesticInternationalIndicator = substr($inputString,88, 2);  $DomesticInternationalIndicator=~s/c// ;
   my $calledSignificantDigitsInNextField = substr($inputString,90, 4);  $calledSignificantDigitsInNextField=~s/c// ;
   my $First15digitsofCalledPartyNumber = substr($inputString,94, 16);  $First15digitsofCalledPartyNumber=~s/c// ;
   my $Digits16to30ofCalledPartyNumber = substr($inputString,110, 16);  $Digits16to30ofCalledPartyNumber=~s/c// ;
   my $ConnectTime = substr($inputString,126, 8);  $ConnectTime=~s/c// ;
   my $ElapsedTime = substr($inputString,134, 10);  $ElapsedTime=~s/c// ;
   my $CompletionIndicator = substr($inputString,144, 4);  $CompletionIndicator=~s/c// ;
 
 # not doing modules yet get the main structure done.  
   $moduleOutput = moduleCodeReader(substr($inputString,148));

 
   # Write out cdr to output file 
   my $outputString = join (',',
   $structureCode, $CallTypeCode, $SensorType, 
   $SensorIdentification, $RecordingOfficeType, $RecordingOfficeIdentification, 
   $Date, $TimingIndicator, $StudyIndicator, $CalledPartyOffHook, 
   $ServiceObservedTrafficSampled, $OperatorAction, $ServiceFeature, 
   $callingSignificantDigitsInNextField, $OriginatingOpenDigits1, $OriginatingOpenDigits2, 
   $OriginatingChargeInformation, $DomesticInternationalIndicator, 
   $calledSignificantDigitsInNextField, $First15digitsofCalledPartyNumber, $Digits16to30ofCalledPartyNumber, 
   $ConnectTime, $ElapsedTime, $CompletionIndicator,  $moduleOutput );

   writeOut("$outputString");
  
# reformat some of the fields/ 
   my $aNumber = formatNumber($callingSignificantDigitsInNextField, $OriginatingOpenDigits1, $OriginatingOpenDigits2, 11,9);
   my $bNumber = formatNumber($calledSignificantDigitsInNextField, $First15digitsofCalledPartyNumber, $Digits16to30ofCalledPartyNumber,15,15);
  $OriginatingChargeInformation=~s/f+// ;

  my $duration = (substr($ElapsedTime,1,5) * 60 + substr($ElapsedTime,6,2)) . "." . substr($ElapsedTime,8,1); # duration in seconds

   my $feature_context_default == "";
   my $feature_service_identifier == "";
   my $feature_service_event == "";
 
   my $npi_protocol_ID == "";
   my $npi_number_ID == "";
   my $npi_captured_NPI == "";
   my $npi_captured_NOA_or_TON == "";
   my $npi_captured_PI == "";

  if ( substr($module611Genericcontextidentifier,0,5) == 80024 ) 
  {  
	$feature_context_default = substr($module611Genericcontextidentifier,5,2);
	$feature_service_identifier = substr($module611Digitsstring,0,12);
	$feature_service_event = substr($module611Digitsstring,12,2);
  }


  if ( substr($module611Genericcontextidentifier,0,5) == 80050 )
  {
        $npi_protocol_ID = substr($module611Digitsstring,0,3);
        $npi_number_ID = substr($module611Digitsstring,3,2);
        $npi_captured_NPI = substr($module611Digitsstring,5,2);
        $npi_captured_NOA_or_TON = substr($module611Digitsstring,7,3);
        $npi_captured_PI = substr($module611Digitsstring,10,1);
   }

# print (" date $Date : year $year : day ". substr($Date,3,2) . " : month ".  substr($Date,1,2) . " : year " . substr($year,0,3) . substr($Date,0,1) . "\n");


   my $cdrGeneratorString = join (',' ,  "x0514" ,  $CallTypeCode, substr($SensorIdentification,1,6) ,
   substr($Date,3,2) . substr($Date,1,2) . substr($year,0,3) . substr($Date,0,1),  # date
   substr($TimingIndicator,0,1) , substr($TimingIndicator,1,1) ,  # field 5 and 6
   substr($StudyIndicator,0,1) , substr($StudyIndicator,1,1), substr($StudyIndicator,2,1), substr($StudyIndicator,3,1),substr($StudyIndicator,5,1),  # fields 7 to 11
   $CalledPartyOffHook,  $ServiceObservedTrafficSampled,  $ServiceFeature,
   "0" . $aNumber, $bNumber,$OriginatingChargeInformation, 
   $ConnectTime, $duration ,  ## connect and elapsed time in seconds
   $CompletionIndicator,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"",
   substr($module104IncomingTrunkIdentificationNumber,1,4) , substr($module104IncomingTrunkIdentificationNumber,5,4),
   substr($module104OutgoingTrunkIdentificationNumber,1,4) , substr($module104OutgoingTrunkIdentificationNumber,5,4),
   "" ,"" ,"" ,"" ,$npi_protocol_ID,$npi_number_ID,$npi_captured_NPI,$npi_captured_NOA_or_TON, $npi_captured_PI , $feature_context_default, $feature_context_default,$feature_service_identifier,$feature_service_event, 
   $module509start, $module509end
   );

   writeGenOut("$cdrGeneratorString");

   return;

}





###############################################################################
# END OF STRUCTURE CODES                                                       
###############################################################################

######################################################
# Reading Module Codes
######################################################

sub moduleCodeReader
{
   my ($moduleString)=@_;
   my $moduleLength=length($moduleString);
   my $stringStart = 0;
		
   my $moduleCode=0;	
   my $moduleCounter = 0;
   my $incomingCount = 0;
   my $outgoingCount = 0;

   $module22PresentDate = 0;
   $module22PresentTime = 0;
   $module25CircuitReleaseDate = 0;
   $module25CircuitReleaseTime = 0;
   $module42CallRecordSequence = 0;
   $module70BearerCapabilities = 0;
   $module70NetworkInterworking = 0;
   $module70SignalingorSupplementaryServiceCapabilitiesUse = 0;
   $module70ReleaseCauseIndicator = 0;
   $module71BearerCapabilities = 0;
   $module71NetworkInterworking = 0;
   $module71ReleaseCauseIndicator = 0;
   $module98CarrierConnectDate = 0;
   $module98CarrierConnectTime = 0;
   $module98MessageDirection = 0;
   $module104IncomingTrunkIdentificationNumber = 0;
   $module104OutgoingTrunkIdentificationNumber = 0;
   $module120CustomerGroupIdentification = 0;
   $module130FacilityReleaseCause = 0;
   $module130CallCharacteristic = 0;
   $module260Start = "";
   $module260End = "";
   $module509start = "";
   $module509end = "";
   $module611Genericcontextidentifier = 0;
   $module611Digitsstring = 0;
   $module612Genericcontextidentifier = 0;
   $module612Genericdigitsstring1 = 0;
   $module612Genericdigitsstring2 = 0;


 # loop while there is still data, through each of the module codes
   while ($stringStart < $moduleLength -4)   # use -4 for 000c end of record
   { 
     $moduleCode= substr($moduleString,$stringStart,3);
     $moduleCode=~s/c//;
     $moduleCode=~s/^0+//; 

     if ($moduleCode == 22)
     {
	logger("found module $moduleCode");
        $module22PresentDate = substr($moduleString, $stringStart +4, 6);  $module22PresentDate=~s/c// ;
        $module22PresentTime = substr($moduleString, $stringStart +10, 8);  $module22PresentTime=~s/c// ;
	$stringStart += 18; 	# length of the structure

     } 
     elsif ($moduleCode == 25)
     {
	logger("found module $moduleCode");
        $module25CircuitReleaseDate = substr($moduleString, $stringStart +4, 6);  $module25CircuitReleaseDate=~s/c// ;
        $module25CircuitReleaseTime = substr($moduleString, $stringStart +10, 8);  $module25CircuitReleaseTime=~s/c// ;
	$stringStart += 18; 	# length of the structure
     }
     elsif ($moduleCode == 42) #
     {
	logger("found module $moduleCode");
        $module42CallRecordSequence = substr($moduleString, $stringStart +4, 8);  $module42CallRecordSequence=~s/c// ;
	$stringStart += 12; 	# length of the structure
     }
     elsif ($moduleCode == 70) #
     {
	logger("found module $moduleCode");
        $module70BearerCapabilities = substr($moduleString, $stringStart +4, 4);  $module70BearerCapabilities=~s/c// ;
        $module70NetworkInterworking = substr($moduleString, $stringStart +8, 2);  $module70NetworkInterworking=~s/c// ;
        $module70SignalingorSupplementaryServiceCapabilitiesUse = substr($moduleString, $stringStart +10, 16);  $module70SignalingorSupplementaryServiceCapabilitiesUse=~s/c// ;
        $module70ReleaseCauseIndicator = substr($moduleString, $stringStart +26, 6);  $module70ReleaseCauseIndicator=~s/c// ;
	$stringStart += 32; 	# length of the structure
     }
     elsif ($moduleCode == 71) # 
     {
	logger("found module $moduleCode");
        $module71BearerCapabilities = substr($moduleString, $stringStart +4, 4);  $module71BearerCapabilities=~s/c// ;
        $module71NetworkInterworking = substr($moduleString, $stringStart +8, 2);  $module71NetworkInterworking=~s/c// ;
        $module71ReleaseCauseIndicator = substr($moduleString, $stringStart +10, 6);  $module71ReleaseCauseIndicator=~s/c// ;
	$stringStart += 16; 	# length of the structure
     }
     elsif ($moduleCode == 98) #
     {
	logger("found module $moduleCode");
        $module98CarrierConnectDate = substr($moduleString, $stringStart +4, 6);  $module98CarrierConnectDate=~s/c// ;
        $module98CarrierConnectTime = substr($moduleString, $stringStart +10, 8);  $module98CarrierConnectTime=~s/c// ;
        $module98MessageDirection = substr($moduleString, $stringStart +18, 2);  $module98MessageDirection=~s/c// ;
	$stringStart += 20; 	# length of the structure
     }
     elsif ($moduleCode == 104) #
     {
	logger("found module $moduleCode");
        my $direction =  substr($moduleString, $stringStart +4, 1);
        if ($direction == 1)   # incoming 
	{
		if ($incomingCount == 0)
            {
              $module104IncomingTrunkIdentificationNumber = substr($moduleString, $stringStart +4, 10);  $module104IncomingTrunkIdentificationNumber=~s/c// ;
            }
            else 
            {
               print ("Extra incoming trunk: $moduleString \n");
            }          
            $incomingCount += 1;
        }
        elsif ($direction == 2)   # incoming 
	{

	    if ($outgoingCount == 0)
            {
              $module104OutgoingTrunkIdentificationNumber = substr($moduleString, $stringStart +4, 10);  $module104OutgoingTrunkIdentificationNumber=~s/c// ;

            }
            else 
            {
               print ("Extra ougoing trunk: $outgoingCount :  $moduleString \n");
            }          
            $outgoingCount += 1;
        }

 
         
	$stringStart += 14; 	# length of the structure
     }
     elsif ($moduleCode == 120) #
     {
        logger("found module $moduleCode" );
        $module120CustomerGroupIdentification = substr($moduleString, $stringStart +4, 6);  $module120CustomerGroupIdentification=~s/c// ;
        $stringStart += 10;     # length of the structure
     }
     elsif ($moduleCode == 130) # 
     {
	logger("found module $moduleCode");
        $module130FacilityReleaseCause = substr($moduleString, $stringStart +4, 6);  $module130FacilityReleaseCause=~s/c// ;
        $module130CallCharacteristic = substr($moduleString, $stringStart +10, 4);  $module130CallCharacteristic=~s/c// ;
	$stringStart += 14; 	# length of the structure
     }
     elsif ($moduleCode == 260) # 
     {
	logger("found module $moduleCode");
        $module260Start .= substr($moduleString, $stringStart +4, 4);  $module260Start=~s/c// ;
        $module260End .=  substr($moduleString, $stringStart +8, 4);  $module260End=~s/c// ;
	$stringStart += 12; 	# length of the structure
     }
     elsif ($moduleCode == 509) # not in spec
     {
	logger("found module $moduleCode");  
        $module509start = substr($moduleString, $stringStart +4, 4);  $module509start=~s/c// ;
        $module509end = substr($moduleString, $stringStart +8, 4);  $module509end=~s/c// ;
	$stringStart += 12; 	# length of the structure
     }
     elsif ($moduleCode == 611) # 
     {
	logger("found module $moduleCode");
        $module611Genericcontextidentifier = substr($moduleString, $stringStart +4, 8);  $module611Genericcontextidentifier=~s/c// ;
        $module611Digitsstring = substr($moduleString, $stringStart +12, 16);  $module611Digitsstring=~s/c// ;
	$stringStart += 28; 	# length of the structure
     }
     elsif ($moduleCode == 612) # 
     {
	logger("found module $moduleCode");
        $module612Genericcontextidentifier = substr($moduleString, $stringStart +4, 8);  $module612Genericcontextidentifier=~s/c// ;
        $module612Genericdigitsstring1 = substr($moduleString, $stringStart +12, 16);  $module612Genericdigitsstring1=~s/c// ;
        $module612Genericdigitsstring2 = substr($moduleString, $stringStart +28, 16);  $module612Genericdigitsstring2=~s/c// ;
	$stringStart += 44; 	# length of the structure
     }
     else
     {
         print ("Unknown module code ". $moduleCode . "\n");
	logger("found unknown module $moduleCode");
         print (substr($moduleString,$stringStart). "\n");
         print ("$moduleString \n");
         return -1;
     }
	
   }	
   
   my $moduleOutput = join(',', $module42CallRecordSequence, $module22PresentDate, $module22PresentTime, 
   $module25CircuitReleaseDate, $module25CircuitReleaseTime, $module70BearerCapabilities, 
   $module70NetworkInterworking, $module70SignalingorSupplementaryServiceCapabilitiesUse, $module70ReleaseCauseIndicator, 
   $module71BearerCapabilities, $module71NetworkInterworking, $module71ReleaseCauseIndicator, 
   $module98CarrierConnectDate, $module98CarrierConnectTime, 
   $module98MessageDirection, $module104OutgoingTrunkIdentificationNumber, $module104IncomingTrunkIdentificationNumber, 
   $module120CustomerGroupIdentification, $module130FacilityReleaseCause, $module130CallCharacteristic,$module260Start, $module260End, $module509start, $module509end, 
   $module611Genericcontextidentifier, $module611Digitsstring, $module612Genericcontextidentifier, $module612Genericdigitsstring1, 
   $module612Genericdigitsstring2 );
   return $moduleOutput;
}

######################################################
# End of reading module Codes
######################################################

######################################################
# Convert phone  numbers
######################################################
sub  formatNumber
{
  my $formatedNumber = 0;
  my ($length, $start, $end, $lengthField1, $lengthField2) = @_;
  if ($length <= $lengthField1)
  {
      $formatedNumber = substr($start,$lengthField1 - $length, $length);
  }
  else
  { 	
      $formatedNumber = $start . substr($end, $lengthField2 - ($length - $lengthField2), ($length - $lengthField2));
  }
  # print ("length $length : start $start : end $end : number $formatedNumber\n");
  return $formatedNumber
}






#######################################################
# Strip out all F & C s from string
#######################################################
sub fcStrip
{
  my ($inputString) = @_;
  $inputString=~s/f|c//g;
  return ($inputString);
}


#######################################################
# Strip out c at end of string
#######################################################
sub cStrip
{
  my ($inputString) = @_;
  $inputString=~s/c$//g;
  return ($inputString);
}


#######################################################
# Strip out f's at beginning of string
#######################################################
sub fStrip
{
  my ($inputString) = @_;
  $inputString=~s/^f+//g;
  return ($inputString);
}


#######################################################
# Log messages and handle debug
#######################################################
sub logger
{
  my ($message)=@_;
  print LOG "$message\n";
  return;
}


#######################################################
# Write out Information to output file
#######################################################
sub writeOut
{
  my ($outputLine)=@_;
  print OUT "$outputLine\n"; 
}

#######################################################
# Write out Information to output file ready for CDR Generator
#######################################################
sub writeGenOut
{
  my ($outputLine)=@_;
  print CDR "$outputLine\n"; 
}
