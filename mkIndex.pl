#!/bin/perl

##################################################
# script   : mkIndex.pl
# author   : Cartesian Limited
# author   : root
# date     : Sat Jun 20 19:34:38 BST 2015
# $Revision: 1.1 
##################################################
$version = "$Revision: 1.1 $number";

# N.B.: add lexically scoped variables and assign them in getArgs ($cols, below)
my $cols = 10;
my $file;
# comment this out if necessary

getArgs(@ARGV);
if (not -f $file)
{
	print "Archive [$file] not specified or does not exist.\n";
	exit 1;
}
if ($file =~ /\//)
{
	print "Please be in the same directory as the archive [$file].\n";
	exit 2;
}

my $dir_name = $file;
$dir_name =~ s/\.tar.gz//;

print "Making $dir_name\n";
`mkdir $dir_name` unless (-d $dir_name);
`cp $file $dir_name`;
my $base_dir = `pwd`;
print "PWD $base_dir\n";

chdir $dir_name;
`tar xzvf $file`;
my $d = `pwd`;
print "DIR $d\n";
if ($d =~ /$dir_name$/)
{
	print "OK\n";
	unlink $file;
}
else
{
	print "OOPS\n";
	exit 3;
}

# begin MAIN section
my $image_dir = "img";
`mkdir $image_dir` unless (-d $image_dir);
my @list = `ls -1 IMG*`;
print "Making thumbnails.\n";
foreach my $f (@list)
{
	chomp $f;
	`convert -thumbnail 100 $f "$image_dir/thumb.$f"`;
}

print "Making index.html .\n";
open OUT, ">index.html";
print OUT "<html><head title=\"Contact Sheet\"></head><body>\n";
my $MORE = 1;
my $img = 0;
while ($MORE)
{
	print OUT "<tr>\n";
	for (my $i = 0; $i < $cols; $i++)
	{
		my $f = $list[$img];
		chomp $f;
		if (++$img > scalar(@list))
		{
			$MORE = 0;
			print OUT "  <td></td>\n";
		}
		else
		{
			print OUT "  <td><img src='img/thumb.$f'></img></td>\n";
		}
	}
	print OUT "</tr>\n";
}
print OUT "</body></html>\n";
close OUT;

`/usr/local/bin/wkhtmltopdf.sh index.html $dir_name.pdf`;
`cp $dir_name.pdf ..`;
`rm -rf img`;
unlink "index.html";

my $this_dir = `pwd`;
print "DIR $this_dir\n";
chdir $base_dir;
chdir "..";

$this_dir = `pwd`;
print "DIR $this_dir\n";

my $tar = $dir_name . ".photos.tar.gz";
`tar czvf $tar $dir_name`;
`rm -rf $dir_name`;
unlink $file;

# put subs below here

# display some help
sub usage
{
	my $script = $0;
	my @parts = split /\//, $script;
	$script = pop(@parts);
	$script =~ s/\.\///;
	print "	$script Version: $version\n\n";
	print "	USAGE:\n\n";
	print "		$script [{-h|--help}] [{-v|--version}] {-f|--cols} colsname\n\n";
	print "\n";
	print "	ARGUMENTS:\n";
	print "		 -h, --help        Display this usage screen.\n";
	print "		 -v, --version     Display version information.\n";
	print "		 -c, --cols        Specify number of columns per row.\n";
	print "		 -f, --file        Specify filename of tar.gz archive.\n";
	print "\n";
	print "	NOTES:\n";
}

# process the arguments -- add as necessary
sub getArgs
{
	while (@_)
	{
		my $arg = shift;
		if ($arg =~ /-h/ || $arg =~ /--help/)
		{
			usage();
			exit;
		}
		elsif ($arg =~ /-v/ || $arg =~ /--version/)
		{
			print "Version: $version\n";
			exit;
		}
		elsif ($arg =~ /-c/ || $arg =~ /--cols/)
		{
			$cols = shift;
		}
		elsif ($arg =~ /-f/ || $arg =~ /--file/)
		{
			$file = shift;
		}
	}
}


=head1 NAME

mkIndex.pl - Some short description


=head1 SYNOPSIS

B<mkIndex.pl> [OPTION] ...

=head1 DESCRIPTION

Place a desription of this here.

=head2 OPTIONS        

Should include options and parameters.


B<-h, --help>
        display some help and usage.

B<-v, --version>
        display version information.


=head1 USAGE

Usage information goes here.


=head1 EXAMPLES

Place examples here.

=head1 RETURN VALUES  

Sections two and three function calls.

=head1 ENVIRONMENT    

Describe environment variables.

=head1 FILES          

Files associated with the subject.

=head1 DIAGNOSTICS    

Normally used for section 4 device interface diagnostics.

=head1 ERRORS         

Sections two and three error and signal handling.

=head1 SEE ALSO       

Cross references and citations.

=head1 STANDARDS      

Conformance to standards if applicable.

=head1 BUGS           

Gotchas and caveats.

=head1 SECURITY CONSIDERATIONS

=head1 COPYRIGHT

Copyright 2015, Cartesian Limited

=cut

