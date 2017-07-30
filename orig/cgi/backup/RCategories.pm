package RCategories;

################################################
# Relation Categories Module
# Last modified 10.10.2003
################################################

use strict;

use vars qw($VERSION @ISA @EXPORT);
$VERSION = "1.00";
@ISA = qw(Exporter);
@EXPORT = qw();

undef %__PACKAGE__::RC_constants;
eval q~
 use Fcntl qw(:DEFAULT :flock :seek);
 %__PACKAGE__::RC_constants = (
	'SEEK_SET'=>SEEK_SET,'SEEK_CUR'=>SEEK_CUR,'SEEK_END'=>SEEK_END,
	'LOCK_SH'=>LOCK_SH,'LOCK_EX'=>LOCK_EX,'LOCK_NB'=>LOCK_NB,'LOCK_UN'=>LOCK_UN,
	'O_RDONLY'=>O_RDONLY,'O_WRONLY'=>O_WRONLY,'O_RDWR'=>O_RDWR,
	'O_APPEND'=>O_APPEND,'O_CREAT'=>O_CREAT,'O_TRUNC'=>O_TRUNC);
~;
if(!defined(%__PACKAGE__::RC_constants))
{
 # For test purposes only!
 # Log that problem!
 %__PACKAGE__::RC_constants = (
	'SEEK_SET'=>0,'SEEK_CUR'=>1,'SEEK_END'=>2,
	'LOCK_SH'=>1,'LOCK_EX'=>2,'LOCK_NB'=>4,'LOCK_UN'=>8,
	'O_RDONLY'=>0,'O_WRONLY'=>1,'O_RDWR'=>2,'O_APPEND'=>8,'O_CREAT'=>0x100,'O_TRUNC'=>0x200);
}

sub AUTOLOAD
{
 my $self = shift;
 my $type = ref($self) or do { print "$self is not an object"; exit; };
 my $name = $RCategories::AUTOLOAD;
 $name =~ s/.*://;
 $name = lc($name);
 unless (exists $self->{__subs}->{$name})
   {
    print "Can't access '$name' field in class $type";
    exit;
   }
 my $ref =  $self->{__subs}->{$name};
 if(wantarray())
  { 
   my @sys_AUTOLOAD_res = &$ref($self,@_);
   return(@sys_AUTOLOAD_res); 
  }
 else 
  {
   my $sys_AUTOLOAD_res = &$ref($self,@_);
   return($sys_AUTOLOAD_res); 
  }
}

sub new
{ 
 my $proto = shift;
 my $class = ref($proto) || $proto;
 my $self = {};
 
 my %inp = @_;

 $self->{'create'}    = defined($inp{'create'}) ? $inp{'create'} : 'Y';
 $self->{'checkdb'}   = defined($inp{'checkdb'}) ? $inp{'checkdb'} : 'Y';
 $self->{'name'}      = defined($inp{'name'}) ?	$inp{'name'} : 'rcatdb';
 $self->{'database'}  = $inp{'database'};
 $self->{'user'}      = $inp{'user'};
 $self->{'pass'}      = $inp{'pass'};
 $self->{'host'}      = $inp{'host'}      || 'localhost';
 $self->{'port'}      = abs(int($inp{'port'})) || '3306';
 $self->{'options'}   = $inp{'options'}   || undef;
 
 my $default_max_array_length = 30000; # Proceed that amount of rows in memory, after that we start swaping!
 my $default_tmp_swap_folder = '/tmp/rcat/';
 my $default_swap_filename = 'RCategories_tmp_';
 my $default_copy_buffer_size = 1048576; # 1MB copy buffer (for swap function)
 
 if(!$self->{'options'}->{'swap'}->{'max_array_length'}) { $self->{'options'}->{'swap'}->{'max_array_length'} = $default_max_array_length; }
 if(!$self->{'options'}->{'swap'}->{'tmp_swap_folder'}) { $self->{'options'}->{'swap'}->{'tmp_swap_folder'} = $default_tmp_swap_folder; }
 if(!$self->{'options'}->{'swap'}->{'swap_filename'}) { $self->{'options'}->{'swap'}->{'swap_filename'} = $default_swap_filename; }
 if(!$self->{'options'}->{'swap'}->{'copy_buffer_size'}) { $self->{'options'}->{'swap'}->{'copy_buffer_size'} = $default_copy_buffer_size; }
 if(!ref($self->{'options'}->{'errors'}->{'messages'})) { $self->{'options'}->{'errors'}->{'messages'} = $__PACKAGE__::default_errors_messages; }
 
 $self->{'structure'} = $inp{'structure'} || $__PACKAGE__::default_tables;
 $self->{'dbh'}       = $inp{'dbh'};
 $self->{'mydbh'}     = 0;
 my $mysql = $self->{'dbh'};
 if(lc(ref($mysql)) eq 'mysql')
  {
   # This is not DBI handler, but we know where it can be found!
   $self->{'dbh'} = $mysql->{'dbh'};
  }
  
 $self->{'error'}	= '';
 $self->{'__subs'}	= {};
 $self->{'__subs'}->{'init'}	= $inp{'init'}	|| \&__rcategory_init;
 $RCategories::error	= '';

 bless($self,$class);
 if($self->init() eq undef)
  {
   return(undef);
  }
 return($self);
}

sub _set_val_RCategories
{
 my $self = shift(@_);
 my $name = shift(@_);
 if(defined($_[0]))
  {
   my $code = '$self->{'."'$name'".'} = $_[0];';
   eval $code;
   return($_[0]);
  }
 else
  {
   my $code = '$code = $self->{'."'$name'".'};';
   eval $code;
   return($code);
  }
}
sub error      { my $r = shift->_set_val_RCategories('error', @_); $RCategories::error = $r; return $r;}
sub errorno    { return ($RCategories::error =~ m/^(\d{1,}\.\d{1,})\:/s) ? $1 : 0;}
sub create     { return shift->_set_val_RCategories('create', @_); }
sub checkdb    { return shift->_set_val_RCategories('checkdb', @_); }
sub database   { return shift->_set_val_RCategories('database', @_); }
sub name       { return shift->_set_val_RCategories('name', @_); }
sub user       { return shift->_set_val_RCategories('user', @_); }
sub pass       { return shift->_set_val_RCategories('pass', @_); }
sub host       { return shift->_set_val_RCategories('host', @_); }
sub port       { return shift->_set_val_RCategories('port', abs(int($_[0]))); }
sub structure  { return shift->_set_val_RCategories('structure', @_); }
sub categories { return shift->_set_val_RCategories('categories', @_); }
sub options    { return shift->_set_val_RCategories('options', @_); }
sub mydbh      { return shift->_set_val_RCategories('mydbh', @_); }
sub dbh
 { 
   my $self = shift();
   if($_[0])
    {
     my $mysql = $_[0];
     if(lc(ref($mysql)) eq 'mysql')
      {
       # This is not DBI handler, but we know where it can be found!
       $_[0] = $mysql->{'dbh'};
      }
     $self->_set_val_RCategories('mydbh', 0);
    }
   $self->_set_val_RCategories('dbh', @_);
 }

sub clear_error
{
 my $self = shift;
 $RCategories::error = '';
 if($self)
  {
   $self->{'error'} = '';
  }
 return(1);
}

sub __rcategory_init
{
 my ($self) = @_;
 my $code = << 'CODE_TERM';
 if($self->{'dbh'} eq undef)
  {
   use DBI;
  }
CODE_TERM
 eval $code;
 if($@ ne '')
   { 
    $self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.1'});
    return(undef);
   }
 
 # Check database (try connect) if db handler is empty
 if(!$self->{'dbh'})
   {
    my $port = $self->{'port'} eq '' ? '' : ';port='.$self->{'port'};
    my $dbh;
    eval { $dbh = DBI->connect("DBI:mysql:".$self->{'database'}.":".$self->{'host'}.$port,$self->{'user'},$self->{'pass'},{PrintError => 0,}); };
    if($dbh)
     {
      $self->{'dbh'} = $dbh;
      $self->{'mydbh'} = 1;
     }
    else
     {
      if($self->{'checkdb'} =~ m/^(Y|YES|ON|TRUE|1)$/si)
        {
         if($DBI::err == 1049) # 1049 Unknown database
          {
           if($self->{'create'} =~ m/^(Y|YES|ON|TRUE|1)$/si)
            {
             my $drh = DBI->install_driver("mysql");
             my $rc = $drh->func('createdb', $self->{'database'}, $self->{'host'}, $self->{'user'}, $self->{'pass'}, 'admin');
             if($rc)
              {
               my $port = $self->{'port'} eq '' ? '' : ';port='.$self->{'port'};
               my $dbh = DBI->connect("DBI:mysql:".$self->{'database'}.":".$self->{'host'}.$port,$self->{'user'},$self->{'pass'},{PrintError => 0,});
               if($dbh)
                 {
                  $self->{'dbh'} = $dbh;
                  $self->{'mydbh'} = 1;
                 }
               else
                 {
                  $self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.2'});
                  return(undef);
                 }
              }
             else
              {
               $self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.3'});
               return(undef);
              }
            }
           else
            {
             $self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.2'});
             return(undef);
            }
          }
         elsif($DBI::err == 1045) # Access denied
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.2'});
           return(undef);
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.2'});
           return(undef);
          }
        }
      else
       {
       	$self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.2'});
        return(undef);
       }
     }
   }
 my $cats_ref = $self->{'structure'}->{'tables'};
 my %cats_s_table = %$cats_ref;
 my @cats_s_table = sort(keys(%cats_s_table));
 my @cats_table   = ();
 foreach (@cats_s_table) {push(@cats_table,$cats_s_table{$_});}
 # Check tables
 if($self->{'checkdb'} =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if($self->{'dbh'})
    {
     my ($dbh,$sth,$numRows,@rows,$i,$l,$ind);
     $dbh = $self->{'dbh'};
     my $search = $self->name().'_';
     $search = $dbh->quote($search);
     $search =~ s/^\'//s;
     $search =~ s/\'$//s;
     $search =~ s/\%/\\\%/sg;
     $search =~ s/\_/\\\_/sg;
     $sth = $dbh->prepare("SHOW TABLES LIKE \'$search\%\'");
     if(!$sth)
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.4'});
       return(undef);
      }
     if($sth->execute())
      {
       $numRows = $sth->rows();
       for($i=0; $i < $numRows; $i++)
        {
         my $aref = $sth->fetchrow_arrayref();
         push(@rows,$$aref[0]);
        }
       $sth->finish();
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.5'});
       return(undef);
      }
     @rows = sort(@rows);
     $ind = 0;
     foreach $l (@cats_s_table)
      {
       $l =~ s/\%\%name\%\%/$self->{'name'}/sgi;
       $l =~ s/\%\%database\%\%/$self->{'database'}/sgi;
       $l =~ s/\%\%user\%\%/$self->{'user'}/sgi;
       $l =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
         
       my $counter = 0;
       foreach $i (@rows)
        {
         if(lc($self->{'name'}.'_'.$l) eq lc($i))
          {
           $counter++;
          }
        }
       if((!$counter) and ($self->{'create'} =~ m/^(Y|YES|ON|TRUE|1)$/si))
        {
         my $sqlq = $cats_table[$ind];
         $sqlq =~ s/\%\%name\%\%/$self->{'name'}/sgi;
         $sqlq =~ s/\%\%database\%\%/$self->{'database'}/sgi;
         $sqlq =~ s/\%\%user\%\%/$self->{'user'}/sgi;
         $sqlq =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
         if(!$dbh->do($sqlq))
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'1.6'});
           return(undef);
          }
        }
       $ind++;
      }
    }
   }
 return(1);
}
sub show_names
{
 my $self = shift;
 $self->clear_error(); # Reset error variable
 if($self->{'dbh'})
  {
   my ($dbh,$sth,$numRows,@rows,$i,$l,$ind);
   $dbh = $self->{'dbh'};
   my $search = '_'.$self->{'structure'}->{'table_names'}->{'rcat_name'};
   $search = $dbh->quote($search);
   $search =~ s/^\'//s;
   $search =~ s/\'$//s;
   $search =~ s/\%/\\\%/sg;
   $search =~ s/\_/\\\_/sg;
   $sth = $dbh->prepare("SHOW TABLES LIKE \'\%$search\'");
   if(!$sth)
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'17.1'});
     return(undef);
    }
   if($sth->execute())
    {
     $numRows = $sth->rows();
     for($i=0; $i < $numRows; $i++)
      {
       my $aref = $sth->fetchrow_arrayref();
       my $name = $$aref[0];
       my $srch = quotemeta('_'.$self->{'structure'}->{'table_names'}->{'rcat_name'});
       if($name =~ m/^(.*)$srch$/s)
        {
         push(@rows,$1);
        }
      }
     $sth->finish();
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'17.2'});
     return(undef);
    }
   if(wantarray()) {return(@rows);} else {return(\@rows);}
  }
 $self->error($self->{'options'}->{'errors'}->{'messages'}->{'17.3'});
 return(undef);
}

sub is_tables_exists
{
  my $self = shift;
  my %inp  = @_;
  my $name = defined($inp{'name'}) ?	$inp{'name'} : $self->{'name'};
  my $counter = 0;
  my $cats_ref = $self->{'structure'}->{'tables'};
  my %cats_s_table = %$cats_ref;
  my @cats_s_table = sort(keys(%cats_s_table));
  my @cats_table   = ();
  foreach (@cats_s_table) {push(@cats_table,$cats_s_table{$_});}
  $self->clear_error(); # Reset error variable
  if($self->{'dbh'})
    {
     my ($dbh,$sth,$numRows,@rows,$i,$l,$ind);
     $dbh = $self->{'dbh'};
     my $search = $name.'_';
     $search = $dbh->quote($search);
     $search =~ s/^\'//s;
     $search =~ s/\'$//s;
     $search =~ s/\%/\\\%/sg;
     $search =~ s/\_/\\\_/sg;
     $sth = $dbh->prepare("SHOW TABLES LIKE \'$search\%\'");
     if(!$sth)
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'14.1'});
       return(undef);
      }
     if($sth->execute())
      {
       $numRows = $sth->rows();
       for($i=0; $i < $numRows; $i++)
        {
         my $aref = $sth->fetchrow_arrayref();
         push(@rows,$$aref[0]);
        }
       $sth->finish();
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'14.2'});
       return(undef);
      }
     @rows = sort(@rows);
     $ind = 0;
     foreach $l (@cats_s_table)
      {
       $l =~ s/\%\%name\%\%/$name/sgi;
       $l =~ s/\%\%database\%\%/$self->{'database'}/sgi;
       $l =~ s/\%\%user\%\%/$self->{'user'}/sgi;
       $l =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
         
       foreach $i (@rows)
        {
         if(lc($name.'_'.$l) eq lc($i))
          {
           $counter++;
          }
        }
       $ind++;
      }
    }
  else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'14.3'});
     return(undef);
    }
  if($counter != scalar(@cats_s_table)) {return(0);}
  return(1);
}

sub create_tables
{
  my $self = shift;
  my %inp  = @_;
  my $name = defined($inp{'name'}) ?	$inp{'name'} : $self->{'name'};
  my $counter = 0;
  my $matched = 0;
  my $t_counter = 0;
  my $cats_ref = $self->{'structure'}->{'tables'};
  my %cats_s_table = %$cats_ref;
  my @cats_s_table = sort(keys(%cats_s_table));
  my @cats_table   = ();
  foreach (@cats_s_table) {push(@cats_table,$cats_s_table{$_});}
  $self->clear_error(); # Reset error variable
  if($self->{'dbh'})
    {
     my ($dbh,$sth,$numRows,@rows,$i,$l,$ind);
     $dbh = $self->{'dbh'};
     my $search = $name.'_';
     $search = $dbh->quote($search);
     $search =~ s/^\'//s;
     $search =~ s/\'$//s;
     $search =~ s/\%/\\\%/sg;
     $search =~ s/\_/\\\_/sg;
     $sth = $dbh->prepare("SHOW TABLES LIKE \'$search\%\'");
     if(!$sth)
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'15.1'});
       return(undef);
      }
     if($sth->execute())
      {
       $numRows = $sth->rows();
       for($i=0; $i < $numRows; $i++)
        {
         my $aref = $sth->fetchrow_arrayref();
         push(@rows,$$aref[0]);
        }
       $sth->finish();
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'15.2'});
       return(undef);
      }
     @rows = sort(@rows);
     $ind = 0;
     foreach $l (@cats_s_table)
      {
       $l =~ s/\%\%name\%\%/$name/sgi;
       $l =~ s/\%\%database\%\%/$self->{'database'}/sgi;
       $l =~ s/\%\%user\%\%/$self->{'user'}/sgi;
       $l =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
       $counter = 0;
       foreach $i (@rows)
        {
         if(lc($name.'_'.$l) eq lc($i))
          {
           $counter++;
          }
        }
       if(!$counter)
        {
         my $sqlq = $cats_table[$ind];
         $sqlq =~ s/\%\%name\%\%/$name/sgi;
         $sqlq =~ s/\%\%database\%\%/$self->{'database'}/sgi;
         $sqlq =~ s/\%\%user\%\%/$self->{'user'}/sgi;
         $sqlq =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
         if(!$dbh->do($sqlq))
          {
       	   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'15.4'});
           return(undef);
          }
         else
          {
           $t_counter++;
          }
        }
       else
        {
         $matched++;
        }
       $ind++;
      }
    }
  else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'15.3'});
     return(undef);
    }
  if(($t_counter+$matched) != scalar(@cats_s_table)) {return(0);}
  return(1);
}

sub find
{
 my $self = shift;
 my %inp  = @_;
 my $caseinsensitive = $inp{'caseinsensitive'}	|| 'Y';
 my $filter          = $inp{'filter'}		|| 'ITEMS';   # Items only, don't match categories,
							      # applicables are: 'ITEMS','ALL','CATEGORIES'
 my $multiple        = $inp{'multiple'}		|| 'Y';       # Return many rows of results.
 my $by              = $inp{'by'}		|| 'ID';      # Search by 'ID', applicables are: 
							      # 'ID','NAME','CID','VALUE'
 my $sort            = $inp{'sort'};			      # Order by feature, applicables are: 
							      # 'ID','NAME','CID','VALUE'
 my $limit           = $inp{'limit'};			      # Limitate results, eg: '0,1'
 my $reverse         = $inp{'reverse'};			      # Reverse selected Categories
 my $partial         = $inp{'partial'};			      # Allows search on partial keyword
 my $search          = $inp{'search'};
 my $additional      = $inp{'additional'};		      # Additional(custom) search condition
 my $check           = $inp{'check'};			      # Check mode
 my $route           = $inp{'route'}		|| 'N';
 my $select          = $inp{'select'}		|| $self->{'structure'}->{'select_columns'};
 my $route_select    = $inp{'route_select'}	|| $select;
 my $rules           = $inp{'rules'};			      # Additional search rules.
 my $like_pattern    = $inp{'like_pattern'}    	|| 'left,right'; # Show where to put '%' pattern!
 
 my @cats = ();
 my @res = ();
 my @tmp = ();
 my $dbh = $self->{'dbh'};
 my $limits = '';
 my $order = '';
 my $where = '';
 my $srch = '';
 my $case = '';
 
 $self->clear_error(); # Reset error variable
 if(!defined($search))
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.1'});
   return(undef);
  }
 
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.2'});
      return(undef);
     }
  }
 $search  = $dbh->quote($search);
 if($partial =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   $search =~ s/^\'//s;
   $search =~ s/\'$//s;
   $search =~ s/\%/\\\%/sg;
   $search =~ s/\_/\\\_/sg;

   $search = "\'".(($like_pattern =~ m/left/si) ? '%' : '').$search.(($like_pattern =~ m/right/si) ? '%' : '')."\'";
   if($search eq "\'%%\'") {$search = "\'%\'";}
   $case   = ' LIKE ';
  }
 else
  {
   $case = ' = ';
  }
 if($dbh)
  {
   if($caseinsensitive =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     $search = uc($search);
     $where = " WHERE UPPER(".$by.")".$case;
    }
   else
    {
     $where = " WHERE ".$by.$case;
    }
   if($multiple =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     $limits = '';
    }
   else
    {
     $limits = ' LIMIT 0,1';
    }
   if($limit ne '')
    {
     $limits = ' LIMIT '.$limit;
    }
   $order = " ORDER BY $sort";
   if($sort eq '') {$order = '';}
   my $rev = '';
   if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
   $srch  = $search;

   $srch = $self->_prepare_rules($rules,$srch);	# Add more search rules to query.
   if($filter =~ m/^(ITEMS|ALL)$/si)
     {
      my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}.$where.$srch.$additional.$order.$limits.$rev;
      my $sth = $dbh->prepare($q);
      my $ref;
      if($sth)
       {
        if($sth->execute())
         {
          while ($ref = $sth->fetchrow_hashref('NAME_uc'))
           {
            $ref->{'type'} = 'I';
            push(@res,$ref);
           }
          $sth->finish();
         }
        else
         {
          $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.3'});
          return(undef);
         }
       }
      else
       {
        $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.4'});
        return(undef);
       }
     }
   if($filter =~ m/^(CATEGORIES|ALL)$/si)
     {
      my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}.$where.$srch.$additional.$order.$limits.$rev;
      my $sth = $dbh->prepare($q);
      my $ref;
      if($sth)
       {
        if($sth->execute())
         {
          while ($ref = $sth->fetchrow_hashref('NAME_uc'))
           {
            $ref->{'type'} = 'C';
            push(@res,$ref);
           }
          $sth->finish();
         }
        else
         {
          $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.5'});
          return(undef);
         }
       }
      else
       {
        $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.6'});
        return(undef);
       }
     }
   if($route =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     my $t;
     my @route_array = ();
     foreach $t (@res)
      {
       my $found = 0;
       my %row = %$t;
       my $CID = $row{'CID'};
       my $iname = '';
       while($CID != 0)
         {
           my $qCID = $dbh->quote($CID);
           my $q = "SELECT ".$route_select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}." WHERE ID=$qCID";
           my $sth = $dbh->prepare($q);
           my $ref;
           if($sth)
            {
             if($sth->execute())
              {
               $ref = $sth->fetchrow_hashref('NAME_uc');
               if(ref($ref))
                {
                 $CID = $ref->{'CID'};
                 push(@route_array,$ref);
                }
               else
                {
                 $CID = 0;
                }
               $sth->finish();
              }
             else
              {
               $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.7'});
               return(undef);
              }
            }
           else
            {
             $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.8'});
             return(undef);
            }
         }
       $row{'route'} = \@route_array;
       push(@tmp,\%row);
      }
     @res = @tmp;
    }
   if(wantarray()) {return(@res);} else {return(\@res);}
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.9'});
   return(undef);
  }
 $self->error($self->{'options'}->{'errors'}->{'messages'}->{'2.10'});
 return(undef);
}

sub add
{
 my $self = shift;
 my %inp  = @_;
 my $type              = $inp{'type'}       || 'ITEM';  # Type: 'ITEM' or 'CATEGORY'
 my $category          = $inp{'category'};		# Category ID; 0 is root
 my $name              = $inp{'name'};			# Item/Category name
 my $value             = $inp{'value'};			# Item/Category value
 my $check             = $inp{'check'};			# Check mode
 my $columns           = $inp{'columns'};		# Hash ref to additional column=>value pairs.
 my $q;
 my $dbh = $self->{'dbh'};
 
 $self->clear_error(); # Reset error variable
 if(!defined($name))
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'3.1'});
   return(undef);
  }
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'3.2'});
      return(undef);
     }
  }
 if($category eq '') {$category = 0;}
 if(!defined($value)) {$value='';}
 
 my $q_category = $dbh->quote($category);
 my $q_name     = $dbh->quote($name);
 my $q_value    = $dbh->quote($value);
 my %hc;
 my $columns_line = '';
 if(ref($columns))
  {
   %hc = %$columns;
   foreach (keys %hc)
    {
     $columns_line .= ', '.$_.'='.$dbh->quote($hc{$_});
    }
  }
 
 if($type =~ m/^ITEM/si)
  {
   $q = "INSERT INTO ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}." SET CID=$q_category, NAME=$q_name, VALUE=$q_value".$columns_line;
  }
 elsif($type =~ m/^CATEGORY/si)
  {
   $q = "INSERT INTO ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}." SET CID=$q_category, NAME=$q_name, VALUE=$q_value".$columns_line;
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'3.3'});
   return(undef);
  }
 my $row = undef;
 my $sth = $dbh->prepare($q);
 if($sth)
  {
   my $resHand = $sth->execute();
   if($resHand)
    {
     $row = $sth->{'mysql_insertid'};
     if($row <= 0)
      {
       eval ('$row = $dbh->func("_InsertID");');
       if(($@ ne '') || ($row <= 0))
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'3.4'});
         $sth->finish();
         return(undef);
        }
      }
     $sth->finish();
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'3.5'});
     return(undef);
    }
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'3.6'});
   return(undef);
  }
 return($row);
}

sub _del_all
{
 my $self = shift;
 my %inp  = @_;
 my $del_related       = $inp{'del_related'}      || 'Y';    # Delete related rows too.
 
 my $q;
 my $dbh = $self->{'dbh'};
 my $succ_qs = 0;
 my $all_qs = 2;
 
 my @qs = ("TRUNCATE TABLE ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'},
           "TRUNCATE TABLE ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'});
 
 if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   push(@qs,"TRUNCATE TABLE ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'});
   push(@qs,"TRUNCATE TABLE ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'});
   $all_qs += 2;
  }
 
 foreach $q (@qs)
  {
   my $lr = $dbh->prepare($q);
   if($lr)
    {
     if($lr->execute())
      {
       $lr->finish();
       $succ_qs++;
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.14'});
      }
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.15'});
    }
  }

 return(($succ_qs == $all_qs) ? 1 : 0);
}

sub lock_tables
{
 my $self = shift;
 my %inp  = @_;
 my $related       = $inp{'related'}      || 'Y';    # Lock/unlock related rows?
 my $unlock        = $inp{'unlock'}       || 'N';    # Ulock tables
 
 my $q;
 my $dbh = $self->{'dbh'};

 if($unlock =~ m/^(Y|YES|ON|TRUE|1)$/si)
   {
    $q = "UNLOCK TABLES";
   }
 else
  {
   if($related =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     $q = "LOCK TABLES ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}." WRITE, ".
          $self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}." WRITE, ".
          $self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." WRITE, ".
          $self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." WRITE";
    }
   else
    {
     $q = "LOCK TABLES ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}." WRITE, ".
          $self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}." WRITE";
    }
  }
 my $lr = $dbh->prepare($q);
 if($lr)
  {
   if($lr->execute())
    {
     $lr->finish();
    }
   else
    {
     if($unlock =~ m/^(Y|YES|ON|TRUE|1)$/si)
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'16.3'});
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'16.1'});
      }
     return(undef);
    }
  }
 else
  {
   if($unlock =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'16.4'});
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'16.2'});
    }
   return(undef);
  }
 return(1);
}

sub del
{
 my $self = shift;
 my %inp  = @_;
 my $type              = $inp{'type'}      	  || 'ITEM'; # Type: 'ITEM' or 'CATEGORY'
 my $id                = $inp{'id'};                         # Item/Category id
 my $item_conditions   = $inp{'item_conditions'};	     # Additional(custom) condition (ITEM)
 my $cat_conditions    = $inp{'cat_conditions'};	     # Additional(custom) condition (CATEGORY)
 my $ritem_conditions  = $inp{'ritem_conditions'};	     # Additional(custom) related condition (ITEM)
 my $rcat_conditions   = $inp{'rcat_conditions'};	     # Additional(custom) related condition (CATEGORY)
 my $check             = $inp{'check'};			     # Check mode
 my $del_related       = $inp{'del_related'}      || 'Y';    # Delete related rows too.

 my $q;
 my $dbh = $self->{'dbh'};
 my $row;
 
 $self->clear_error(); # Reset error variable
 if($id eq '')
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.1'});
   return(undef);
  }
 
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.2'});
      return(undef);
     }
  }
 
 if(($id == 0) && ($type =~ m/^CATEGORY/si))
  {
   # Bulk delete (i.e. TRUNCATE)
   return($self->_del_all('del_related'=>$del_related));
  }
 
 my $q_id = $dbh->quote($id);
 my $where = " WHERE ID=$q_id";
 if($type =~ m/^ITEM/si)
  {
   if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     if($self->lock_tables('related'=>$del_related,'unlock'=>'N') eq undef) {return(undef);}
    }
   $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}.$where.$item_conditions;
   my $sth = $dbh->prepare($q);
   if($sth)
    {
     if($sth->execute())
      {
       $row = $sth->rows();
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.5'});
       if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si) { if($self->lock_tables('related'=>$del_related,'unlock'=>'Y') eq undef) {return(undef);} }
       return(undef);
      }
     $sth->finish();
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.6'});
     if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si) { if($self->lock_tables('related'=>$del_related,'unlock'=>'Y') eq undef) {return(undef);} }
     return(undef);
    }
   if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." WHERE ID=$q_id OR ITEM_DEST=$q_id".$ritem_conditions;
     my $sth = $dbh->prepare($q);
     if($sth)
      {
       if($sth->execute())
        {
         $sth->finish();
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.7'});
         if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si) { if($self->lock_tables('related'=>$del_related,'unlock'=>'Y') eq undef) {return(undef);} }
         return(undef);
        }
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.8'});
       if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si) { if($self->lock_tables('related'=>$del_related,'unlock'=>'Y') eq undef) {return(undef);} }
       return(undef);
      }
     $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." WHERE ITEM_DEST=$q_id".$ritem_conditions;
     $sth = $dbh->prepare($q);
     if($sth)
      {
       if($sth->execute())
        {
         $sth->finish();
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.7'});
         if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si) { if($self->lock_tables('related'=>$del_related,'unlock'=>'Y') eq undef) {return(undef);} }
         return(undef);
        }
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.8'});
       if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si) { if($self->lock_tables('related'=>$del_related,'unlock'=>'Y') eq undef) {return(undef);} }
       return(undef);
      }
    }
   if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     if($self->lock_tables('related'=>$del_related,'unlock'=>'Y') eq undef) {return(undef);}
    }
  }
 elsif($type =~ m/^CATEGORY/si)
  {
   local $__PACKAGE__::root_id          = $id;
   local $__PACKAGE__::root             = $inp{'root'} || 'Y'; # Delete 'root' category i.e $id (if category)!
   local $__PACKAGE__::del_related      = $del_related;
   local $__PACKAGE__::ritem_conditions = $ritem_conditions;
   local $__PACKAGE__::rcat_conditions  = $rcat_conditions;
   
   if($self->lock_tables('related'=>$del_related,'unlock'=>'N') eq undef) {return(undef);}
   
   $row = $self->traverse('eval'=>\&__category_del,'cid'=>$id,'additional'=>$cat_conditions);
   
   if($self->lock_tables('related'=>$del_related,'unlock'=>'Y') eq undef) {return(undef);}
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.11'});
   return(undef);
  }
 return($row);
}

sub __category_del
{
 my $self = shift;
 my %inp  = @_;
 
 my $id              = $inp{'id'};
 my $cid             = $inp{'cid'};
 my $rID = '';
 my $rDEL = 'Y';
 my $andDontRemoverParent = '';
 
 if(!($__PACKAGE__::root =~ m/^(Y|YES|ON|TRUE|1)$/si))
  {
   if($__PACKAGE__::root_id == $id) { return(1); }
  }
 
 my $del_related 	= $__PACKAGE__::del_related;
 my $ritem_conditions	= $__PACKAGE__::ritem_conditions;
 my $rcat_conditions	= $__PACKAGE__::rcat_conditions;
 
 my $dbh  = $self->{'dbh'};
 my $qCID = $dbh->quote($id);
 my ($q,$row);
 my $count = 0;

 if($id != 0)
  {
   $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}." WHERE ID=$qCID";
   my $sth = $dbh->prepare($q);
   if($sth)
    {
     if($sth->execute())
      {
       $count += $sth->rows();
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.5'});
       return(undef);
      }
     $sth->finish();
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.6'});
     return(undef);
    }
   if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." WHERE ID=$qCID OR CAT_DEST=$qCID".$rcat_conditions;
     my $sth = $dbh->prepare($q);
     if($sth)
      {
       if($sth->execute())
        {
         $sth->finish();
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.7'});
         return(undef);
        }
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.8'});
       return(undef);
      }
     $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." WHERE CAT_DEST=$qCID".$ritem_conditions;
     $sth = $dbh->prepare($q);
     if($sth)
      {
       if($sth->execute())
        {
         $sth->finish();
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.7'});
         return(undef);
        }
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.8'});
       return(undef);
      }
    }
  }
 if($del_related =~ m/^(Y|YES|ON|TRUE|1)$/si)
   {
    my $lcnt = 5000; # Used to split a really big selects.
    my $lcrn = 0;
    my $crows = $lcnt;
    while($crows == $lcnt)
     {
      my $LIMIT = " LIMIT $lcrn,$lcnt";
      $q = "SELECT ID FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}." WHERE CID=$qCID".$LIMIT;
      my $sth = $dbh->prepare($q);
      my $ref;
      if($sth)
       {
        if($sth->execute())
         {
          $crows = int($sth->rows());
          $lcrn += $crows;
          while($ref = $sth->fetchrow_arrayref())
            {
             my @row = @$ref;
             my $qCID = $dbh->quote($row[0]);
             $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." WHERE ID=$qCID OR ITEM_DEST=$qCID".$ritem_conditions;
             my $sth = $dbh->prepare($q);
             if($sth)
              {
               if($sth->execute())
                 {
                  $sth->finish();
                 }
               else
                 {
                  $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.7'});
                  return(undef);
                 }
              }
             else
              {
               $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.8'});
               return(undef);
              }
             $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." WHERE ITEM_DEST=$qCID".$ritem_conditions;
             $sth = $dbh->prepare($q);
             if($sth)
              {
               if($sth->execute())
                 {
                  $sth->finish();
                 }
               else
                 {
                  $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.7'});
                  return(undef);
                 }
              }
             else
              {
               $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.8'});
               return(undef);
              }
            }
         }
        else
         {
          $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.12'});
          return(undef);
         }
        $sth->finish();
       }
      else
       {
        $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.13'});
        return(undef);
       }
     }
   }
 $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}." WHERE CID=$qCID";
 my $sth = $dbh->prepare($q);
 if($sth)
  {
   if($sth->execute())
    {
     $count += $sth->rows();
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.5'});
     return(undef);
    }
   $sth->finish();
  }
 else
   {
    $self->error($self->{'options'}->{'errors'}->{'messages'}->{'4.6'});
    return(undef);
   }
 return($count);
}

sub modify
{
 my $self = shift;
 my %inp  = @_;
 my $type              = $inp{'type'}       || 'ITEM';	# Type: 'ITEM' or 'CATEGORY'
 my $id                = $inp{'id'};			# Item/Category id
 my $additional        = $inp{'additional'};		# Additional(custom) condition
 my $newcid            = $inp{'newcid'};                # New 'parent' ID (CID/PARENT)
 my $newid             = $inp{'newid'};                 # New ID
 my $check             = $inp{'check'};			# Check mode
 my $name              = $inp{'name'};			# ITEM/CATEGORY name
 my $value             = $inp{'value'};			# ITEM/CATEGORY value
 my $columns           = $inp{'columns'};		# Hash ref to additional column=>value pairs.
 my $modify_related    = $inp{'modify_related'} || 'Y'; # Modify related rows too.
 
 my $q;
 my ($table_name,$set);
 my $aff = 0;
 my $dbh = $self->{'dbh'};
 
 $self->clear_error(); # Reset error variable
 if($id eq '')
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'5.1'});
   return(undef);
  }
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'5.2'});
      return(undef);
     }
  }
 if($type =~ m/^ITEM/si)
  {
   $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'};
  }
 elsif($type =~ m/^CATEGORY/si)
  {
   $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'};
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'5.3'});
   return(undef);
  }
 if(defined($newcid) && ($newcid ne ''))
   {
    my $qcid = $dbh->quote($newcid);
    $set     = "CID=$qcid";
   }
 if(defined($newid) && ($newid ne ''))
   {
    my $qid = $dbh->quote($newid);
    if($set ne '') {$set .= ",";}
    $set     .= "ID=$qid";
   }
 if(defined($name))
  {
   my $qname = $dbh->quote($name);
   if($set ne '') {$set .= ",";}
   $set     .= "NAME=$qname";
  }
 if(defined($value))
   {
    my $qvalue = $dbh->quote($value);
    if($set) {$set .= ",";}
    $set     .= "VALUE=$qvalue";
   }
 my %hc;
 if(ref($columns))
  {
   %hc = %$columns;
   foreach (keys %hc)
    {
     if($set ne '') {$set .= ",";}
     $set .= $_.'='.$dbh->quote($hc{$_});
    }
  }
 my $locked = 0;
 if($set ne '')
  {
   my $q_id  = $dbh->quote($id);
   if(defined($newid) && ($newid ne ''))
     {
       $locked = 1;
       if($self->lock_tables('related'=>'Y','unlock'=>'N') eq undef) {return(undef);}
     }
   $q = "UPDATE $table_name SET $set WHERE ID=$q_id".$additional;
   my $sth = $dbh->prepare($q);
   if($sth)
    {
     if($sth->execute())
      {
       $aff = $sth->rows();
       $sth->finish();
       my $res = 1;
       if(defined($newid) && ($newid ne '') && ($aff) && ($type =~ m/^CATEGORY/si))
         {
       	  $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'};
       	  $q = "UPDATE $table_name SET CID=".$dbh->quote($newid)." WHERE CID=".$dbh->quote($id);
          $sth = $dbh->prepare($q);
          if($sth)
           {
            if($sth->execute()) { $res = 1; }
            else { $res = 0; }
            $sth->finish();
           }
          if($res)
           {
       	    $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'};
       	    $q = "UPDATE $table_name SET CID=".$dbh->quote($newid)." WHERE CID=".$dbh->quote($id);
            $sth = $dbh->prepare($q);
            if($sth)
             {
              if($sth->execute()) { $res = 1; }
              else { $res = 0; }
              $sth->finish();
             }
       	   }
         }
       if(defined($newid) && ($newid ne '') && ($aff) && ($modify_related =~ m/^(Y|YES|ON|TRUE|1)$/si))
         {
          if(($type =~ m/^ITEM/si) && ($res))
           {
            $res = 1;
            $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'};
       	    $q = "UPDATE $table_name SET ID=".$dbh->quote($newid)." WHERE ID=".$dbh->quote($id);
            $sth = $dbh->prepare($q);
            if($sth)
             {
              if($sth->execute()) { $res = 1; }
              else { $res = 0; }
              $sth->finish();
             }
            if($res)
             {
       	      $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'};
       	      $q = "UPDATE $table_name SET ITEM_DEST=".$dbh->quote($newid)." WHERE ITEM_DEST=".$dbh->quote($id);
              $sth = $dbh->prepare($q);
              if($sth)
               {
                if($sth->execute()) { $res = 1; }
                else { $res = 0; }
                $sth->finish();
               }
       	     }
       	    if($res)
             {
       	      $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'};
       	      $q = "UPDATE $table_name SET ITEM_DEST=".$dbh->quote($newid)." WHERE ITEM_DEST=".$dbh->quote($id);
              $sth = $dbh->prepare($q);
              if($sth)
               {
                if($sth->execute()) { $res = 1; }
                else { $res = 0; }
                $sth->finish();
               }
       	     }
           }
          if(($type =~ m/^CATEGORY/si) && ($res))
           {
            $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'};
       	    $q = "UPDATE $table_name SET ID=".$dbh->quote($newid)." WHERE ID=".$dbh->quote($id);
            $sth = $dbh->prepare($q);
            if($sth)
             {
              if($sth->execute()) { $res = 1; }
              else { $res = 0; }
              $sth->finish();
             }
            if($res)
             {
       	      $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'};
       	      $q = "UPDATE $table_name SET CAT_DEST=".$dbh->quote($newid)." WHERE CAT_DEST=".$dbh->quote($id);
              $sth = $dbh->prepare($q);
              if($sth)
               {
                if($sth->execute()) { $res = 1; }
                else { $res = 0; }
                $sth->finish();
               }
       	     }
       	    if($res)
             {
       	      $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'};
       	      $q = "UPDATE $table_name SET CAT_DEST=".$dbh->quote($newid)." WHERE CAT_DEST=".$dbh->quote($id);
              $sth = $dbh->prepare($q);
              if($sth)
               {
                if($sth->execute()) { $res = 1; }
                else { $res = 0; }
                $sth->finish();
               }
       	     }
           }
         }
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'5.6'});
       if($locked) { if($self->lock_tables('related'=>'Y','unlock'=>'Y') eq undef) {return(undef);} }
       return(undef);
      }
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'5.7'});
     if($locked) { if($self->lock_tables('related'=>'Y','unlock'=>'Y') eq undef) {return(undef);} }
     return(undef);
    }
  }
 if($locked)
  {
   if($self->lock_tables('related'=>'Y','unlock'=>'Y') eq undef) {return(undef);}
  }
 return($aff);
}

# --- Long rows support: Low level functions ---

# Function set
sub rc_save_data_to_file
{
 my %inp = @_;
 my $array_ref	= $inp{'array'};
 my $quote 	= defined($inp{'quote'}) ?	$inp{'quote'} : 0;
 local *FILEHANDLE;
 my $oldmask = umask;
 
 umask(0177); # umask 0177 is equal to mask 0600 (wr-------)
 # Open for enlarge.
 open(FILEHANDLE,'>>'.$inp{'filename'}) or do{umask($oldmask); return(undef);};
 umask($oldmask);
 
 if(ref($array_ref))
  {
   my @array = @$array_ref;
   my $row;
   my @rows;
   my $buf;
   foreach $row (@array)
    {
     my $data = '';
     if($row ne '')
      {
       if(ref($row) eq 'ARRAY')
        {
         @rows = @$row;
         foreach $row (@rows)
          {
           if($data ne '') {$data .= ',';}
           $data .= rc_escape_data($row);
          }
        }
       else
        {
         if($quote) {$data = rc_escape_data($row);}
         else {$data = $row;}
        }
       $buf .= $data."\n";
      }
    }
   return (print FILEHANDLE $buf);
  }
 return(undef);
}

sub rc_load_data_from_file
{
 my %inp = @_;
 my @array = ();
 my $quote 	= defined($inp{'quote'}) ?	$inp{'quote'} : 0;
 my $count 	= defined($inp{'count'}) ?	$inp{'count'} : 0;
 my $copy_buffer_size = $inp{'copy_buffer_size'};
 local *FILEHANDLE;
 local $/ = "\n";
 my $i = 0;
 open(FILEHANDLE,$inp{'filename'}) or return(undef);
 if(!seek(FILEHANDLE,0,$__PACKAGE__::RC_constants{'SEEK_SET'})) { return(undef); }
 
 while($i < $count)
  {
   my $row = readline(\*FILEHANDLE);
   if($row ne undef)
    {
     $i++;
     if($quote)
      {
      	my @rows = split(/\,/,$row);
      	my @er = ();
      	my ($el,$els) = ();
      	foreach $el (@rows)
      	  {
      	   chomp($el);
      	   $el = rc_unescape_data($el);
      	   if(scalar(@rows) > 1) {push(@er,$el);}
      	   else {$els = $el;}
      	  }
        if(scalar(@er) > 1)
      	 {
      	  push(@array,\@er);
      	 }
       else { push(@array,$els); }
      }
     else
      {
       chomp($row);
       push(@array,$row);
      }
    }
   else
    {
     if($i > 0) { last; }
     else { return(undef); }
    }
  }
 my $position = tell(FILEHANDLE);
 close(FILEHANDLE);
 if($position < 0) { return(undef); }
 rc_swap_file_from('src'=>$inp{'filename'},'dest'=>$inp{'filename'}.'_copy','position'=>$position,'copy_buffer_size'=>$copy_buffer_size);
 return(\@array);
}

sub rc_go_to_row
{
 my %inp = @_;
 my $count 	= defined($inp{'count'}) ?	$inp{'count'} : 0;
 local *FILEHANDLE;
 local $/ = "\n";
 my $i = 0;
 open(FILEHANDLE,$inp{'filename'}) or return(undef);
 if(!seek(FILEHANDLE,0,$__PACKAGE__::RC_constants{'SEEK_SET'})) { return(undef); }
 
 while($i < $count)
  {
   my $row = readline(\*FILEHANDLE);
   if($row ne undef)
    {
     $i++;
    }
   else { return(undef); }
  }
 my $position = tell(FILEHANDLE);
 close(FILEHANDLE);
 if($position < 0) { return(undef); }
 return($position);
}

sub rc_swap_file_from
{
 my %inp = @_;
 my $src = $inp{'src'};
 my $dest = $inp{'dest'};
 my $position 	= defined($inp{'position'}) ?	$inp{'position'} : 0;
 my $copy_buffer_size 	= defined($inp{'copy_buffer_size'}) ?	$inp{'copy_buffer_size'} : 1048576; # Default 1 MB cache!
 
 local (*SRC,*DEST);
 my ($buf,$bytes);
 
 my $size = (-s $src);
 if(!$size) { return(undef); }
 $size -= $position;
 if($size < 0) { return(undef); }
 my $left = $size;
 
 open(SRC,$src) or return(undef);
 if(!seek(SRC,$position,$__PACKAGE__::RC_constants{'SEEK_SET'})) {close SRC; return(undef);}
 
 my $oldmask = umask;
 umask(0177); # umask 0177 is equal to mask 0600 (wr-------)
 open(DEST,'>'.$dest) or do {close SRC; umask($oldmask); return(undef);};
 umask($oldmask);
 
 while($left)
  {
   $bytes = read(SRC,$buf,$copy_buffer_size);
   if($bytes ne undef)
    {
     $left -= $bytes;
     if($bytes == 0) { last; }
     if(!print DEST $buf)
      {
       close SRC;
       close DEST;
       unlink $dest;
       return(undef);
      }
    }
   else
    {
     close SRC;
     close DEST;
     unlink $dest;
     return(undef);
    }
  }
 close SRC;
 close DEST;
 if(!unlink($src))  { return(undef); }
 if(!rename($dest,$src)) { return(undef); }
 
 return(1);
}

sub rc_create_file
{
 my %inp = @_;
 my $folder = $inp{'folder'} || '/tmp/';
 my $filename = $inp{'filename'} || 'RCategories_tmp_';
 my $i=0;
 local *TMPFILE;
 my $oldmask = umask;
 my $randname = rand()*1000000;
 
 if((!-e $folder) || (!-d $folder))
  {
   umask(0111); # umask 0111 is equal to mask 0666
   mkdir($folder,0666);
  }
 while(-e $folder.$filename.$<.'_'.$$.'_'.$randname.'.tmp')
  {
   $randname = rand()*1000000;
   $i++;
   if($i > 100) { return(undef); }
  }
 umask(0177); # umask 0177 is equal to mask 0600 (wr-------)
 open(TMPFILE,'>'.$folder.$filename.$<.'_'.$$.'_'.$randname.'.tmp') or do{umask($oldmask); return(undef);};
 close TMPFILE;
 umask($oldmask);
 return($folder.$filename.$<.'_'.$$.'_'.$randname.'.tmp');
}

sub rc_remove_unused_files
{
 my %inp = @_;
 my $folder = $inp{'folder'} || '/tmp/';
 my $filename = $inp{'filename'};
 my $epoch = $inp{'epoch'};
 my ($file,$del_cnt) = ('',0);
 
 opendir(DIRHANDLER,$folder) or return(undef);
 
 my $qf = quotemeta($filename);
 
 while($file = readdir(DIRHANDLER))
  {
   if($file =~ m/^$qf/s)
    {
     my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)= stat($folder.$file);
     if(($ctime+$epoch) < time())
      {
       if(!unlink($folder.$file)) { return(undef); } # Fail - can't delete unused files!
       $del_cnt++;
      }
    }
  }
 return($del_cnt);
}

sub rc_remove_data_file
{
 my %inp = @_;
 my $filename = $inp{'filename'};
 my $i=0;
 local *TMPFILE;

 while(-e $filename)
  {
   if(open(TMPFILE,$filename))
    {
     close TMPFILE;
     if(unlink($filename)) { return(1); }
    }
   $i++;
   if($i > 20) { return(undef); }
  }
 return(1);
}

sub rc_escape_data
{
 my $str = shift;
 my ($escape, $row_sep, $col_sep) = ('%',"\n",',');

 my $esc_hex = uc($escape.join('',unpack("Hh", $escape x 2)));
 my $row_hex = uc($escape.join('',unpack("Hh",$row_sep x 2)));
 my $col_hex = uc($escape.join('',unpack("Hh",$col_sep x 2)));
   
 $escape = quotemeta($escape);
 $row_sep = quotemeta($row_sep);
 $col_sep = quotemeta($col_sep);
    
 $str =~ s/$escape/$esc_hex/gs;
 $str =~ s/$row_sep/$row_hex/gs;  
 $str =~ s/$col_sep/$col_hex/gs;
 return($str);
}

sub rc_unescape_data
{
 my $enstr = shift;
 my ($escape, $row_sep, $col_sep) = ('%',"\n",',');

 my $esc_hex = uc($escape.join('',unpack("Hh", $escape x 2)));
 my $row_hex = uc($escape.join('',unpack("Hh",$row_sep x 2)));
 my $col_hex = uc($escape.join('',unpack("Hh",$col_sep x 2)));
    
 $enstr =~ s/$esc_hex/$escape/gs;
 $enstr =~ s/$row_hex/$row_sep/gs;  
 $enstr =~ s/$col_hex/$col_sep/gs;
 return($enstr);
}

sub rc_read_from_stream
{
 my $query = shift;
 my $dbh = shift;
 my $row_start = shift;
 my $row_count = shift;
 $query .= " LIMIT $row_start,$row_count";
 my @queue = ();
 
 my $sth = $dbh->prepare($query);
 my $ref;
 if($sth)
  {
   if($sth->execute())
     {
      while($ref = $sth->fetchrow_arrayref())
        {
         my @row = @$ref;
         push(@queue,$row[0]); # Push ID
        }
     }
   else { return(undef); }
   $sth->finish();
  }
 else { return(undef); }
 return(\@queue);
}

sub traverse
{
 my $self = shift;
 my %inp  = @_;
 my $cid               = $inp{'cid'};		# Category id
 my $evala             = $inp{'eval'};		# Code that will be evaluated
 my $check             = $inp{'check'};		# Check mode
 my $sort              = $inp{'sort'};		# Sort Items/Categories by $sort
 my $reverse           = $inp{'reverse'};	# Reverse selected Categories
 my $additional        = $inp{'additional'};	# Additional(custom) condition

 my $q;
 my $dbh = $self->{'dbh'};
 my @queue = ();
 my $current = '';
 my $cnt = 0;
 
 $self->clear_error(); # Reset error variable
 my $order = " ORDER BY $sort";
 if($sort eq '') {$order = '';}

 if(!defined($cid) || ($cid eq ''))
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.1'});
   return(undef);
  }

 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.2'});
      return(undef);
     }
  }

 # --- Long rows support: Variables ---
 my %options = ('max_array_length'=>$self->{'options'}->{'swap'}->{'max_array_length'},
  		'tmp_swap_folder'=>$self->{'options'}->{'swap'}->{'tmp_swap_folder'},
  		'swap_filename'=>$self->{'options'}->{'swap'}->{'swap_filename'},
  		'swapflag'=>0, 'array_size'=>0, 'total_size'=>0, 'last_read'=>0, 'filename'=>'');

 # Remove files older than 2 days.
 rc_remove_unused_files('folder'=>$options{'tmp_swap_folder'},'filename'=>$options{'swap_filename'},'epoch'=>60*60*24*2);

 if($cid == 0)
  {
   my $qCID = $dbh->quote($cid);
   my $rev = '';
   if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
   
   $q = "SELECT ID FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}." WHERE CID=$qCID$additional$order$reverse";
   
   # --- Long rows support: Part 1 (traverse from root) ---
   my $row_start=0;
   while(1) # While current "select" give fresh results
     {
      my $ref_data = rc_read_from_stream($q,$dbh,$row_start,$options{'max_array_length'});	# Read current part of rows.
      if($ref_data eq undef)
       {
        if($options{'swapflag'})
         {
          rc_remove_data_file('filename'=>$options{'filename'});
         }
        $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.3'});
        return(undef);
       }
      my @data = @$ref_data;
      undef $ref_data;
      $options{'last_read'} = scalar(@data);		# Find size of rows from last read.
      if($options{'last_read'})				# If last read returns any rows.
        {
         $row_start += $options{'last_read'};
         # If we do not swapping and @array can hold all items
         if(!$options{'swapflag'} and (($options{'array_size'}+$options{'last_read'}) <= $options{'max_array_length'}))
           {
            push(@queue,@data);
            $options{'array_size'} += $options{'last_read'};
           }
         elsif($options{'swapflag'}) # If we use swapping
           {
            if(rc_save_data_to_file('array'=>\@data,'filename'=>$options{'filename'},'quote'=>0) eq undef)
             {
              if($options{'swapflag'})
               {
                rc_remove_data_file('filename'=>$options{'filename'});
               }
              $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.4'});
              return(undef);
             }
            $options{'total_size'} += $options{'last_read'};
           }
         # If @array can't hold all items
         elsif(($options{'array_size'}+$options{'last_read'}) > $options{'max_array_length'})
           {
            $options{'swapflag'} = 1;
            $options{'filename'} = rc_create_file('folder'=>$options{'tmp_swap_folder'},'filename'=>$options{'swap_filename'});
            if($options{'filename'} eq undef)
             {
              if($options{'swapflag'})
               {
                rc_remove_data_file('filename'=>$options{'filename'});
               }
              $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.5'});
              return(undef);
             }
            if(rc_save_data_to_file('array'=>\@data,'filename'=>$options{'filename'},'quote'=>0) eq undef)
             {
              if($options{'swapflag'})
               {
                rc_remove_data_file('filename'=>$options{'filename'});
               }
              $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.4'});
              return(undef);
             }
            $options{'total_size'} += $options{'last_read'};
           }
        }
      if($options{'last_read'} != $options{'max_array_length'})
        {
         last;
        } # No more results from 'this' query
     }
   # --- Long rows support: Part 1 ENDS ---
   $current = 0;
   $qCID = $dbh->quote($current);
   $cnt++;
   if(ref($evala))
     {
      &$evala($self,'id'=>$current,'cid'=>$cid);
     }
    else
     {
      eval $evala;
     }
  }
 else
  {
   push(@queue,$cid);
   $options{'array_size'} += 1;
  }

 while(scalar(@queue))
  {   
   # Proceed with current item from array
   $current = shift(@queue);
   $options{'array_size'}--;
   
   my $qCID = $dbh->quote($current);
   my $rev = '';
   if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
     
   $q = "SELECT ID FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}." WHERE CID=$qCID$additional$order$reverse";

   # --- Long rows support: Part 2 (traverse queue) ---
   my $row_start=0;
   while(1) # While current "select" give fresh results
     {
      my $ref_data = rc_read_from_stream($q,$dbh,$row_start,$options{'max_array_length'});	# Read current part of rows.
      if($ref_data eq undef)
       {
        if($options{'swapflag'})
         {
          rc_remove_data_file('filename'=>$options{'filename'});
         }
        $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.3'});
        return(undef);
       }
      my @data = @$ref_data;
      undef $ref_data;
      $options{'last_read'} = scalar(@data);		# Find size of rows from last read.
      if($options{'last_read'})				# If last read returns any rows.
        {
         $row_start += $options{'last_read'};
         # If we do not swapping and @array can hold all items
         if(!$options{'swapflag'} and (($options{'array_size'}+$options{'last_read'}) <= $options{'max_array_length'}))
           {
            push(@queue,@data);
            $options{'array_size'} += $options{'last_read'};
           }
         elsif($options{'swapflag'}) # If we use swapping
           {
            if(rc_save_data_to_file('array'=>\@data,'filename'=>$options{'filename'},'quote'=>0) eq undef)
             {
              if($options{'swapflag'})
               {
                rc_remove_data_file('filename'=>$options{'filename'});
               }
              $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.4'});
              return(undef);
             }
            $options{'total_size'} += $options{'last_read'};
           }
         # If @array can't hold all items
         elsif(($options{'array_size'}+$options{'last_read'}) > $options{'max_array_length'})
           {
            $options{'swapflag'} = 1;
            $options{'filename'} = rc_create_file('folder'=>$options{'tmp_swap_folder'},'filename'=>$options{'swap_filename'});
            if($options{'filename'} eq undef)
             {
              if($options{'swapflag'})
               {
                rc_remove_data_file('filename'=>$options{'filename'});
               }
              $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.5'});
              return(undef);
             }
            if(rc_save_data_to_file('array'=>\@data,'filename'=>$options{'filename'},'quote'=>0) eq undef)
             {
              if($options{'swapflag'})
               {
                rc_remove_data_file('filename'=>$options{'filename'});
               }
              $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.4'});
              return(undef);
             }
            $options{'total_size'} += $options{'last_read'};
           }
        }
      if($options{'last_read'} != $options{'max_array_length'})
        {
         last;
        } # No more results from 'this' query
     }

   if(!$options{'array_size'} && $options{'total_size'})	# If array is empty we need to read some from file (if any)
    {
     my $data = rc_load_data_from_file('count'=>int($options{'max_array_length'}),'filename'=>$options{'filename'},'quote'=>0,'copy_buffer_size'=>$self->{'options'}->{'swap'}->{'copy_buffer_size'});
     if(ref($data))
      {
       @queue = @$data;
       $options{'array_size'} = scalar(@queue);
       if($options{'array_size'} < int($options{'max_array_length'}))
        {
         rc_remove_data_file('filename'=>$options{'filename'});
         $options{'swapflag'} = 0;
        }
       $options{'total_size'} -= $options{'array_size'};
      }
     else
      {
       if($data eq undef)
         {
          if($options{'swapflag'})
           {
            rc_remove_data_file('filename'=>$options{'filename'});
           }
          $self->error($self->{'options'}->{'errors'}->{'messages'}->{'6.6'});
          return(undef);
         }
      }
    }
   
   if(!$options{'total_size'} and !$options{'array_size'})
    {
     rc_remove_data_file('filename'=>$options{'filename'});
     $options{'swapflag'} = 0;
    }
   # --- Long rows support: Part 2 ENDS ---

   $cnt++;
   if(ref($evala))
     {
      &$evala($self,'id'=>$current,'cid'=>$cid);
     }
    else
     {
      eval $evala;
     }
  }
 return($cnt);
}

sub deep_traverse
{
 my $self = shift;
 my %inp  = @_;
 my $id              = $inp{'id'};
 my $level           = $inp{'level'};
 my $separator       = $inp{'separator'}   || '//';
 my $evala           = $inp{'eval'};		# Code that will be evaluated
 my $sort            = $inp{'sort'};		# Sort Items/Categories by $sort
 my $reverse         = $inp{'reverse'};		# Reverse selected Categories
 my $item_conditions = $inp{'item_conditions'};	# Additional(custom) condition (ITEM)
 my $cat_conditions  = $inp{'cat_conditions'};	# Additional(custom) condition (CATEGORY)

 my $select          = $inp{'select'}      || $self->{'structure'}->{'select_columns'};
 my $columns         = $inp{'columns'};
 my $max_level 	     = defined($inp{'max_level'}) ?	$inp{'max_level'} : 0;# Max level in deep to traverse!

 my $dbh = $self->{'dbh'};
 my @cats = ();
 my $q;
 my ($i,$item,$item_name,$item_value,$item_columns);
 
 if(!$level)
  {
   my @path = ();
   $self->{'__dt_array'} = undef;
   $self->{'__dt_array'} = \@path;
  }
 
 my $order = " ORDER BY $sort";
 if($sort eq '') {$order = '';}

 $self->clear_error(); # Reset error variable
 
 $level++;
 
 if(ref($evala))
  {
   $columns->{'type'} = 'C';
   $columns->{'route'} = $self->{'__dt_array'};
   &$evala($self,'id'=>$id,'level'=>$level,'separator'=>$separator,'columns'=>$columns);
  }
 else
  {
   eval $evala;
  }
 if($max_level && ($level == $max_level)) { return(1); }
 my @row_refs = ();
 my $current_index = 0;
 my $all_current_rows = 0;
 
 my $qCID = $dbh->quote($id);
 my $rev = '';
 if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
   
 $q = "SELECT $select FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}." WHERE CID=$qCID".$cat_conditions.$order.$rev;
 my $sth = $dbh->prepare($q);
 my $ref;
 if($sth)
  {
   if($sth->execute())
    {
     while ($ref = $sth->fetchrow_hashref('NAME_uc'))
      {
       $ref->{'type'} = 'C';
       unshift(@row_refs,$ref);
      }
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'7.1'});
     return(undef);
    }
   $sth->finish();
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'7.2'});
   return(undef);
  }
 $all_current_rows = scalar(@row_refs);
 for ($i=1;$i<=$all_current_rows;$i++)
  {
    $item_columns = pop(@row_refs);
    
    my $path_ptr = $self->{'__dt_array'};
    my @path = @$path_ptr;
    push(@path,$item_columns);
    $self->{'__dt_array'} = \@path;
    
    $self->deep_traverse('id'=>$item_columns->{'ID'},'level'=>$level,'separator'=>$separator,'eval'=>$evala,
    			 'columns'=>$item_columns,'max_level'=>$max_level);
    
    $path_ptr = $self->{'__dt_array'};
    @path = @$path_ptr;
    pop(@path);
    $self->{'__dt_array'} = \@path;
  }
 @row_refs = ();
 $qCID = $dbh->quote($id);

 $rev = '';
 if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
   
 $q = "SELECT $select FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}." WHERE CID=$qCID".$item_conditions.$order.$rev;
 $sth = $dbh->prepare($q);
 if($sth)
  {
   if($sth->execute())
    {
     while ($ref = $sth->fetchrow_hashref('NAME_uc'))
      {
       $ref->{'type'} = 'I';
       unshift(@row_refs,$ref);
      }
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'7.3'});
     return(undef);
    }
   $sth->finish();
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'7.4'});
   return(undef);
  }
 $all_current_rows = scalar(@row_refs);
 for ($i=1;$i<=$all_current_rows;$i++)
   {
    $item_columns = pop(@row_refs);
    if(ref($evala))
     {
      $item_columns->{'route'} = $self->{'__dt_array'};
      &$evala($self,'id'=>$id,'level'=>$level,'separator'=>$separator,'columns'=>$item_columns);
     }
    else
     {
      eval $evala;
     }
   }
 if(!$level)
  {
   $self->{'__dt_array'} = undef;
  }
 return(1);
}

sub load_category
{
 my $self = shift;
 my %inp  = @_;
 my $cid             = $inp{'cid'};		# Category id
 my $item_conditions = $inp{'item_conditions'};	# Additional(custom) condition (ITEM)
 my $cat_conditions  = $inp{'cat_conditions'};	# Additional(custom) condition (CATEGORY)
 my $sort            = $inp{'sort'};		# Sort Items/Categories by $sort
 my $reverse         = $inp{'reverse'};		# Reverse selected Categories
 my $select          = $inp{'select'}      || $self->{'structure'}->{'select_columns'};

 my @res = ();
 my @cats;
 my $dbh = $self->{'dbh'};
 my $q;
 
 my $order = " ORDER BY $sort";
 if($sort eq '') {$order = '';}
 
 $self->clear_error(); # Reset error variable

 my $qCID = $dbh->quote($cid);
 
 my $rev = '';
 if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
   
 $q = "SELECT $select FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}." WHERE CID=$qCID".$cat_conditions.$order.$rev;
 my $sth = $dbh->prepare($q);
 my $ref;
 if($sth)
  {
   if($sth->execute())
    {
     while($ref = $sth->fetchrow_hashref('NAME_uc'))
      {
       $ref->{'type'} = 'C';
       push(@res,$ref);
      }
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'8.1'});
     return(undef);
    }
   $sth->finish();
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'8.2'});
   return(undef);
  }
 $rev = '';
 if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
 
 $q = "SELECT $select FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}." WHERE CID=$qCID".$item_conditions.$order.$rev;
 $sth = $dbh->prepare($q);
 if($sth)
  {
   if($sth->execute())
     {
      while($ref = $sth->fetchrow_hashref('NAME_uc'))
      {
       $ref->{'type'} = 'I';
       push(@res,$ref);
      }
     }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'8.3'});
     return(undef);
    }
   $sth->finish();
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'8.4'});
   return(undef);
  }
 if(wantarray()) {return(@res);} else {return(\@res);}
}

sub read
{
 my $self = shift;
 my %inp  = @_;
 my $caseinsensitive = $inp{'caseinsensitive'}    || 'Y';
 my $sort            = $inp{'sort'};		# Sort by 'NAME', applicables are: 
 						# 'ID','NAME','CID','PARENT','VALUE'
 my $reverse         = $inp{'reverse'};		# Reverse selected Categories
 my $separator       = $inp{'separator'}          || '//';
 my $path            = $inp{'path'}               || $separator;
 my $partial         = $inp{'partial'};		# Allows search on partial keyword (ITEMS only)
 my $parent          = $inp{'parent'} ?	$inp{'parent'} : 0;# Assume new root ID for that search.
 my $check           = $inp{'check'};		# Check mode
 my $item_conditions = $inp{'item_conditions'};	# Additional(custom) condition (ITEM)
 my $cat_conditions  = $inp{'cat_conditions'};	# Additional(custom) condition (CATEGORY)
 my $select          = $inp{'select'}             || $self->{'structure'}->{'select_columns'};
 my $like_pattern    = $inp{'like_pattern'}       || 'left,right'; # Show where to put '%' pattern!

 my @cats = ();
 my @res = ();
 my %cres = ();
 my @parts = ();
 my @path_array = ();
 my $item = '';
 my $dbh = $self->{'dbh'};
 my $order = '';
 my $where = '';
 my ($l,$value,$mpar,$mpath) = ();
 my $result = '';
 my $case = '';

 $self->clear_error(); # Reset error variable
 $order = " ORDER BY $sort";
 if($sort eq '') {$order = '';}
 
 if($path eq '') 
   {
    $self->error($self->{'options'}->{'errors'}->{'messages'}->{'9.1'});
    return(undef);
   }
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'9.2'});
      return(undef);
     }
  }
 if($dbh)
  {
   my $rev = '';
   if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
   
   my $qsep = quotemeta($separator);
   @parts = split(/$qsep/s,$path);
   if($path =~ m/$qsep$/s)
    {
     $item = '';
    }
   else
    {
     $item = pop(@parts);
    }
   foreach $l (@parts)
    {
     if($parent eq undef)
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'9.3'});
       return(undef);
      }
     $l =~ s/\ {1,}$//si;
     $l =~ s/^\ {1,}//si;
     if($l ne '')
       {
        if($caseinsensitive =~ m/^(Y|YES|ON|TRUE|1)$/si)
          {
           $l = uc($l);
           $where = " WHERE UPPER(NAME)=";
          }
        else
          {
           $where = " WHERE NAME=";
          }
        my $qCID  = $dbh->quote($parent);
        my $qname = $dbh->quote($l);
        my $q = "SELECT $select FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'cat_name'}.$where."$qname AND CID=$qCID".$cat_conditions.$order.$rev;
        my $sth = $dbh->prepare($q);
        my $ref;
        if($sth)
         {
          if($sth->execute())
           {
            $ref = $sth->fetchrow_hashref('NAME_uc');
            if(ref($ref))
             {
              %cres = %$ref;
              my $ID = $ref->{'ID'};
              $result  = $ID;
              $ref->{'NAME'} = $l if($ref->{'NAME'} eq '');
              $ref->{'type'} = 'C';
              push(@path_array,$ref);
             }
            else
             {
              $result = undef;
             }
           }
          else
           {
            $self->error($self->{'options'}->{'errors'}->{'messages'}->{'9.4'});
            return(undef);
           }
          $sth->finish();
         }
        else
         {
          $self->error($self->{'options'}->{'errors'}->{'messages'}->{'9.5'});
          return(undef);
         }
        $parent = $result;
       }
      }
     if($item ne '')
      {
       if($item eq '*') {$item = '';}
       $item = $dbh->quote($item);
       if($partial =~ m/^(Y|YES|ON|TRUE|1)$/si)
         {
          $item =~ s/^\'//s;
   	  $item =~ s/\'$//s;
   	  $item =~ s/\%/\\\%/sg;
   	  $item =~ s/\_/\\\_/sg;

   	  $item = "\'".(($like_pattern =~ m/left/si) ? '%' : '').$item.(($like_pattern =~ m/right/si) ? '%' : '')."\'";
   	  if($item eq "\'%%\'") {$item = "\'%\'";}
   	  $case   = ' LIKE ';
         }
       else
         {
          $case = ' = ';
         }
       if($caseinsensitive =~ m/^(Y|YES|ON|TRUE|1)$/si)
         {
          $l = uc($item);
          $where = " WHERE UPPER(NAME)$case";
         }
       else
         {
          $l = $item;
          $where = " WHERE NAME$case";
         }
       my $qCID  = $dbh->quote($result);
       my $qname = $l;
       my $q = "SELECT $select FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'item_name'}.$where."$qname AND CID=$qCID".$item_conditions.$order.$rev;
       my $sth = $dbh->prepare($q);
       my $ref;
       if($sth)
        {
         if($sth->execute())
          {
           if($sth->rows())
             {
              while($ref = $sth->fetchrow_hashref('NAME_uc'))
                {
                 $ref->{'type'} = 'I';
                 $ref->{'route'} = \@path_array;
                 push(@res,$ref);
                }
             }
           $sth->finish();
          }
         else
           {
            $self->error($self->{'options'}->{'errors'}->{'messages'}->{'9.6'});
            return(undef);
           }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'9.7'});
         return(undef);
        }
      }
     else
      {
       if($result ne undef)
        {
         my %row = %cres;
         $row{'route'} = \@path_array;
         $row{'type'} = 'C';
         push(@res,\%row);
        }
       elsif($path eq $separator)
        {
         my %row = ('ID'=>0,'CID'=>'','NAME'=>'ROOT','VALUE'=>'','QUALIFIER'=>'','route'=>\@path_array,'type'=>'C');
         push(@res,\%row);
        }
      }
   if(wantarray()) {return(@res);} else {return(\@res);}
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'9.8'});
   return(undef);
  }
 $self->error($self->{'options'}->{'errors'}->{'messages'}->{'9.9'});
 return(undef);
}

# Relation add method
# Here we can have two different types of relations: Relations for CATEGORIES and relations for ITEMS.
# So you can add relation for "x" category (CATEGORY context) to category or some item.
sub r_add
{
 my $self = shift;
 my %inp  = @_;
 my $type              = $inp{'type'}       || 'ITEM';  # Type: 'ITEM' or 'CATEGORY'
 my $id	               = $inp{'id'};		# ID of object
 my $cat_dest          = $inp{'cat_dest'};
 my $item_dest         = $inp{'item_dest'};
 my $relation          = $inp{'relation'};	# Relation between objects
 my $check             = $inp{'check'};		# Check mode
 my $columns           = $inp{'columns'};	# Hash ref to additional column=>value pairs.
 my $q;
 my $dbh = $self->{'dbh'};
 
 $self->clear_error(); # Reset error variable
 #if(($id eq undef) || (($cat_dest eq '') && ($item_dest eq '')))
 # Fix: 04.03.2003 - Texts only relations
 if($id eq '')
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'10.1'});
   return(undef);
  }
 if(!defined($relation))
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'10.2'});
   return(undef);
  }
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'10.3'});
      return(undef);
     }
  }
 if(!defined($cat_dest)) {$cat_dest='';}
 if(!defined($item_dest)) {$item_dest='';}
 
 my $q_id 	= $dbh->quote($id);
 my $q_cat_dest = $dbh->quote($cat_dest);
 my $q_item_dest = $dbh->quote($item_dest);
 my $q_relation = $dbh->quote($relation);
 my %hc;
 my $columns_line = '';
 if(ref($columns))
  {
   %hc = %$columns;
   foreach (keys %hc)
    {
     $columns_line .= ', '.$_.'='.$dbh->quote($hc{$_});
    }
  }
 
 if($type =~ m/^ITEM/si)
  {
   $q = "INSERT INTO ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." SET ID=$q_id, RELATION=$q_relation, CAT_DEST=$q_cat_dest, ITEM_DEST=$q_item_dest".$columns_line;
  }
 elsif($type =~ m/^CATEGORY/si)
  {
   $q = "INSERT INTO ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." SET ID=$q_id, RELATION=$q_relation, CAT_DEST=$q_cat_dest, ITEM_DEST=$q_item_dest".$columns_line;
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'10.4'});
   return(undef);
  }
 my $row = undef;
 my $sth = $dbh->prepare($q);
 if($sth)
  {
   my $resHand = $sth->execute();
   if($resHand)
    {
     $row = $sth->{'mysql_insertid'};
     if($row <= 0)
      {
       eval ('$row = $dbh->func("_InsertID");');
       if(($@ ne '') || ($row <= 0))
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'10.5'});
         $sth->finish();
         return(undef);
        }
      }
     $sth->finish();
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'10.6'});
     return(undef);
    }
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'10.7'});
   return(undef);
  }
 return($row);
}

sub r_del
{
 my $self = shift;
 my %inp  = @_;
 my $type              = $inp{'type'}       || 'ITEM';  # Type: 'ITEM' or 'CATEGORY'
 my $id                = $inp{'id'};			# Item/Category id
 my $item_conditions   = $inp{'item_conditions'};	# Additional(custom) condition (ITEM)
 my $cat_conditions    = $inp{'cat_conditions'};	# Additional(custom) condition (CATEGORY)
 my $check             = $inp{'check'};			# Check mode

 my $q;
 my $dbh = $self->{'dbh'};
 my $row;
 
 $self->clear_error(); # Reset error variable
 
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'11.1'});
      return(undef);
     }
  }

 my $q_id = $dbh->quote($id);
 my $where = " WHERE UID=$q_id";
 
 if($type =~ m/^ITEM/si)
  {
   if(($id eq '') && ($item_conditions ne ''))
     {
      $where = " WHERE";
     }
   elsif($id eq '')
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'11.2'});
      return(undef);
     }
   $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}.$where.$item_conditions;
   my $sth = $dbh->prepare($q);
   if($sth)
    {
     if($sth->execute())
      {
       $row = $sth->rows();
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'11.3'});
       return(undef);
      }
     $sth->finish();
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'11.4'});
     return(undef);
    }
  }
 elsif($type =~ m/^CATEGORY/si)
  {
   if(($id eq '') && ($cat_conditions ne ''))
     {
      $where = " WHERE";
     }
   elsif($id eq '')
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'11.5'});
      return(undef);
     }
   $q = "DELETE FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}.$where.$cat_conditions;
   my $sth = $dbh->prepare($q);
   if($sth)
    {
     if($sth->execute())
      {
       $row = $sth->rows();
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'11.6'});
       return(undef);
      }
     $sth->finish();
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'11.7'});
     return(undef);
    }
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'11.8'});
   return(undef);
  }
 return($row);
}

sub r_find
{
 my $self = shift;
 my %inp  = @_;
 my $caseinsensitive = $inp{'caseinsensitive'}	|| 'Y';
 my $filter          = $inp{'filter'}		|| 'ITEMS';	# Items only, don't match categories,
								# applicables are: 'ITEMS','ALL','CATEGORIES'
 my $multiple        = $inp{'multiple'}		|| 'Y';		# Return many rows of results.
 my $by              = $inp{'by'}		|| 'ID';	# Search by 'ID', applicables are: 
								# 'UID','ID','RELATION','CAT_DEST','ITEM_DEST',...
 my $sort            = $inp{'sort'};				# Order by feature, applicables are: 
								# 'UID','ID','RELATION','CAT_DEST','ITEM_DEST',...
 my $limit           = $inp{'limit'};				# Limitate results, eg: '0,1'
 my $reverse         = $inp{'reverse'};				# Reverse selected Categories
 my $partial         = $inp{'partial'};				# Allows search on partial keyword
 my $search          = $inp{'search'};
 my $additional      = $inp{'additional'};			# Additional(custom) search condition
 my $check           = $inp{'check'};				# Check mode
 my $separator       = $inp{'separator'}	|| '//';
 my $select          = $inp{'select'}		|| $self->{'structure'}->{'r_select_columns'};
 my $rules           = $inp{'rules'};				# Additional search rules.
 my $like_pattern    = $inp{'like_pattern'}    	|| 'left,right';# Show where to put '%' pattern!
 
 my @cats = ();
 my @res = ();
 my @tmp = ();
 my $dbh = $self->{'dbh'};
 my $limits = '';
 my $order = '';
 my $where = '';
 my $srch = '';
 my $case = '';
 
 $self->clear_error(); # Reset error variable
 
 if(!defined($search))
   {
    $self->error($self->{'options'}->{'errors'}->{'messages'}->{'12.1'});
    return(undef);
   }
 
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'12.2'});
      return(undef);
     }
  }
 $search  = $dbh->quote($search);
 if($partial =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   $search =~ s/^\'//s;
   $search =~ s/\'$//s;
   $search =~ s/\%/\\\%/sg;
   $search =~ s/\_/\\\_/sg;
   	 
   $search = "\'".(($like_pattern =~ m/left/si) ? '%' : '').$search.(($like_pattern =~ m/right/si) ? '%' : '')."\'";
   if($search eq "\'%%\'") {$search = "\'%\'";}
   $case   = ' LIKE ';
  }
 else
  {
   $case = ' = ';
  }
 if($dbh)
  {
   if($caseinsensitive =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     $search = uc($search);
     $where = " WHERE UPPER(".$by.")".$case;
    }
   else
    {
     $where = " WHERE ".$by.$case;
    }
   if($multiple =~ m/^(Y|YES|ON|TRUE|1)$/si)
    {
     $limits = '';
    }
   else
    {
     $limits = ' LIMIT 0,1';
    }
   if($limit ne '')
    {
     $limits = ' LIMIT '.$limit;
    }
   $order = " ORDER BY $sort";
   if($sort eq '') {$order = '';}
   my $rev = '';
   if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
   $srch  = $search;
   
   $srch = $self->_prepare_rules($rules,$srch);	# Add more search rules to query.
   
   if($filter =~ m/^(CATEGORIES|ALL)$/si)
     {
      my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}.$where.$srch.$additional.$order.$limits.$rev;
      my $sth = $dbh->prepare($q);
      my $ref;
      if($sth)
       {
        if($sth->execute())
         {
          while ($ref = $sth->fetchrow_hashref('NAME_uc'))
           {
            $ref->{'type'} = 'C';
            push(@res,$ref);
           }
          $sth->finish();
         }
        else
         {
          $self->error($self->{'options'}->{'errors'}->{'messages'}->{'12.5'});
          return(undef);
         }
       }
      else
       {
        $self->error($self->{'options'}->{'errors'}->{'messages'}->{'12.6'});
        return(undef);
       }
     }
   if($filter =~ m/^(ITEMS|ALL)$/si)
     {
      my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}.$where.$srch.$additional.$order.$limits.$rev;
      my $sth = $dbh->prepare($q);
      my $ref;
      if($sth)
       {
        if($sth->execute())
         {
          while ($ref = $sth->fetchrow_hashref('NAME_uc'))
           {
            $ref->{'type'} = 'I';
            push(@res,$ref);
           }
          $sth->finish();
         }
        else
         {
          $self->error($self->{'options'}->{'errors'}->{'messages'}->{'12.3'});
          return(undef);
         }
       }
      else
       {
        $self->error($self->{'options'}->{'errors'}->{'messages'}->{'12.4'});
        return(undef);
       }
     }
   if(wantarray()) {return(@res);} else {return(\@res);}
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'12.7'});
   return(undef);
  }
 return(undef);
}

# Locate all rows which contain $item or $category, but filtered by $filter (i.e for 'ITEMS' function
# will returns only these rows which has $item/$category =>(to) 'ITEM' relations). In other words 'ITEMS'
# filter will returns only 'ITEMS' relations and 'ALL' will return all rows which contain $item/$category id!
# To understand how function works take a look at the example in the bottom of this file.
sub r_list
{
 my $self = shift;
 my %inp  = @_;
 my $filter          = $inp{'filter'}		|| 'ITEMS';	# A little bit different semantic here!!!
								# applicables are: 'ITEMS','ALL','CATEGORIES'
 my $sort            = $inp{'sort'};				# Order by feature, applicables are: 
								# 'UID','ID','RELATION','CAT_DEST','ITEM_DEST',...
 my $limit           = $inp{'limit'};				# Limitate results, eg: '0,1'
 my $reverse         = $inp{'reverse'};				# Reverse selected Categories
 my $additional      = $inp{'additional'};			# Additional(custom) search condition
 my $check           = $inp{'check'};				# Check mode
 my $select          = $inp{'select'}		|| $self->{'structure'}->{'r_select_columns'};
 my $rules           = $inp{'rules'};				# Additional search rules.
 my $category        = $inp{'category'};
 my $item            = $inp{'item'};
 
 my @cats = ();
 my @res = ();
 my @tmp = ();
 my $dbh = $self->{'dbh'};
 my $limits = '';
 my $order = '';
 my $srch = '';
 my $case = ' = ';
 
 $self->clear_error(); # Reset error variable
 
 if(!defined($item) && !defined($category))
   {
    $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.1'});
    return(undef);
   }
 
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.2'});
      return(undef);
     }
  }

 if($dbh)
  {
   if($limit ne '')
    {
     $limits = ' LIMIT '.$limit;
    }
   $order = " ORDER BY $sort";
   if($sort eq '') {$order = '';}
   my $rev = '';
   if(($order ne '') && ($reverse =~ m/^(Y|YES|ON|TRUE|1)$/si)){$rev = ' DESC';}
   
   if(defined($category) && ($category > 0))
    {
     $srch  = $dbh->quote($category);
     $srch = $self->_prepare_rules($rules,$srch);	# Add more search rules to query.
     if($filter =~ m/^CATEGORIES$/si)
      {
       my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." WHERE (ID=$srch AND ITEM_DEST=0) OR CAT_DEST=$srch".$additional.$order.$limits.$rev;
       my $sth = $dbh->prepare($q);
       my $ref;
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'C';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.5'});
           return(undef);
          }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.6'});
         return(undef);
        }
      }
     if($filter =~ m/^ALL$/si)
      {
       my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." WHERE ID=$srch OR CAT_DEST=$srch".$additional.$order.$limits.$rev;
       my $sth = $dbh->prepare($q);
       my $ref;
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'C';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.5'});
           return(undef);
          }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.6'});
         return(undef);
        }
       $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." WHERE CAT_DEST=$srch".$additional.$order.$limits.$rev;
       $sth = $dbh->prepare($q);
       $ref='';
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'I';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.3'});
           return(undef);
          }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.4'});
         return(undef);
        }
      }
    if($filter =~ m/^ITEMS$/si)
      {
       my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." WHERE ID=$srch AND CAT_DEST=0".$additional.$order.$limits.$rev;
       my $sth = $dbh->prepare($q);
       my $ref;
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'C';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.5'});
           return(undef);
          }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.6'});
         return(undef);
        }
       $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." WHERE CAT_DEST=$srch".$additional.$order.$limits.$rev;
       $sth = $dbh->prepare($q);
       $ref='';
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'I';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.3'});
           return(undef);
          }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.4'});
         return(undef);
        }
      }
    }
   if(defined($item) && ($item > 0))
    {
     $srch  = $dbh->quote($item);
     $srch = $self->_prepare_rules($rules,$srch);	# Add more search rules to query.
     if($filter =~ m/^CATEGORIES$/si)
      {
       my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." WHERE ITEM_DEST=$srch".$additional.$order.$limits.$rev;
       my $sth = $dbh->prepare($q);
       my $ref;
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'C';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.3'});
           return(undef);
          }
        }
       my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." WHERE ID=$srch AND ITEM_DEST=0".$additional.$order.$limits.$rev;
       my $sth = $dbh->prepare($q);
       my $ref;
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'I';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.3'});
           return(undef);
          }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.4'});
         return(undef);
        }
      }
    if($filter =~ m/^ALL$/si)
      {
       my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'}." WHERE ITEM_DEST=$srch".$additional.$order.$limits.$rev;
       my $sth = $dbh->prepare($q);
       my $ref;
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'C';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.5'});
           return(undef);
          }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.6'});
         return(undef);
        }
       $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." WHERE ID=$srch OR ITEM_DEST=$srch".$additional.$order.$limits.$rev;
       $sth = $dbh->prepare($q);
       $ref='';
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'I';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.3'});
           return(undef);
          }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.4'});
         return(undef);
        }
      }
     if($filter =~ m/^ITEMS$/si)
      {
       my $q = "SELECT ".$select." FROM ".$self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'}." WHERE (ID=$srch AND CAT_DEST=0) OR ITEM_DEST=$srch".$additional.$order.$limits.$rev;
       my $sth = $dbh->prepare($q);
       my $ref;
       if($sth)
        {
         if($sth->execute())
          {
           while ($ref = $sth->fetchrow_hashref('NAME_uc'))
            {
             $ref->{'type'} = 'I';
             push(@res,$ref);
            }
           $sth->finish();
          }
         else
          {
           $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.3'});
           return(undef);
          }
        }
       else
        {
         $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.4'});
         return(undef);
        }
      }
    }
   if(wantarray()) {return(@res);} else {return(\@res);}
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'18.7'});
   return(undef);
  }
 return(undef);
}

sub r_modify
{
 my $self = shift;
 my %inp  = @_;
 my $type              = $inp{'type'}       || 'ITEM';  # Type: 'ITEM' or 'CATEGORY'
 my $uid               = $inp{'uid'};			# Unique relate id (UID)
 my $additional        = $inp{'additional'};	  	# Additional(custom) condition
 my $newuid            = $inp{'newuid'};                # New UID
 my $id                = $inp{'id'};                    # New ID
 my $relation          = $inp{'relation'};              # New relation
 my $cat_dest          = $inp{'cat_dest'};              # New 'CAT_DEST' ID
 my $item_dest         = $inp{'item_dest'};             # New 'ITEM_DEST' ID
 my $check             = $inp{'check'};			# Check mode
 my $columns           = $inp{'columns'};		# Hash ref to additional column=>value pairs.
 
 my $q;
 my ($table_name,$set);
 my $aff = 0;
 my $dbh = $self->{'dbh'};
 
 $self->clear_error(); # Reset error variable
 if(!defined($uid) || ($uid eq ''))
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'13.1'});
   return(undef);
  }
 if($check =~ m/^(Y|YES|ON|TRUE|1)$/si)
  {
   if(!$self->is_tables_exists())
     {
      $self->error($self->{'options'}->{'errors'}->{'messages'}->{'13.2'});
      return(undef);
     }
  }
 if($type =~ m/^ITEM/si)
  {
   $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'ritem_name'};
  }
 elsif($type =~ m/^CATEGORY/si)
  {
   $table_name = $self->name().'_'.$self->{'structure'}->{'table_names'}->{'rcat_name'};
  }
 else
  {
   $self->error($self->{'options'}->{'errors'}->{'messages'}->{'13.3'});
   return(undef);
  }
 if(defined($newuid) && ($newuid ne ''))
   {
    my $qnewuid = $dbh->quote($newuid);
    $set     = "UID=$qnewuid";
   }
 if(defined($id) && ($id ne ''))
   {
    my $qid = $dbh->quote($id);
    if($set ne '') {$set .= ",";}
    $set     .= "ID=$qid";
   }
 if(defined($relation))
   {
    my $qrelation = $dbh->quote($relation);
    if($set ne '') {$set .= ",";}
    $set     .= "RELATION=$qrelation";
   }
 if(defined($cat_dest))
  {
   my $qcat_dest = $dbh->quote($cat_dest);
   if($set ne '') {$set .= ",";}
   $set     .= "CAT_DEST=$qcat_dest";
  }
 if(defined($item_dest))
   {
    my $qitem_dest = $dbh->quote($item_dest);
    if($set) {$set .= ",";}
    $set     .= "ITEM_DEST=$qitem_dest";
   }
 my %hc;
 if(ref($columns))
  {
   %hc = %$columns;
   foreach (keys %hc)
    {
     if($set ne '') {$set .= ",";}
     $set .= $_.'='.$dbh->quote($hc{$_});
    }
  }
 my $locked = 0;
 if($set ne '')
  {
   my $q_uid  = $dbh->quote($uid);
   $q = "UPDATE $table_name SET $set WHERE UID=$q_uid".$additional;
   my $sth = $dbh->prepare($q);
   if($sth)
    {
     if($sth->execute())
      {
       $aff = $sth->rows();
       $sth->finish();
      }
     else
      {
       $self->error($self->{'options'}->{'errors'}->{'messages'}->{'13.4'});
       return(undef);
      }
    }
   else
    {
     $self->error($self->{'options'}->{'errors'}->{'messages'}->{'13.5'});
     return(undef);
    }
  }
 return($aff);
}

sub _prepare_rules
{
 my $self  = shift;
 my $rules = shift;
 my $rules_line = shift || '';
 my $dbh   = $self->{'dbh'};
 my %hr;
 if(ref($rules))
  {
   %hr = %$rules;
   my $cord;
   my @order = ();
   if($hr{'_properties'}->{'columns_order'} ne undef)
    {
     $cord = $hr{'_properties'}->{'columns_order'};
     if(length($cord) > 0) { @order = split(',',$cord); }
    }
   delete($hr{'_properties'});
   if(!scalar(@order))
    {
     @order = keys %hr;
    }
   my $key;
   foreach $key (@order)
    {
     my $rf = $hr{$key};
     if(ref($rf))
      {
       my $r_caseinsensitive = $rf->{'caseinsensitive'} || 'N';
       my $r_logic = $rf->{'logic'} || 'AND';
       my $r_partial = $rf->{'partial'} || 'N';
       my $r_value = $rf->{'value'} || '';
       my $r_like_pattern = $rf->{'like_pattern'} || 'left,right';
       my ($case,$where);
       if($rules_line ne '') {$rules_line .= ' '.$r_logic;}
       
       $r_value = $dbh->quote($r_value);
       
       if($r_partial =~ m/^(Y|YES|ON|TRUE|1)$/si)
  	{
  	 $r_value =~ s/^\'//s;
  	 $r_value =~ s/\'$//s;
	 $r_value =~ s/\%/\\\%/sg;
   	 $r_value =~ s/\_/\\\_/sg;
   	 
   	 $r_value = "\'".(($r_like_pattern =~ m/left/si) ? '%' : '').$r_value.(($r_like_pattern =~ m/right/si) ? '%' : '')."\'";
   	 $case   = ' LIKE ';
  	}
       else
  	{
   	 $case = ' = ';
  	}
       if($r_caseinsensitive =~ m/^(Y|YES|ON|TRUE|1)$/si)
	{
	 $r_value = uc($r_value);
	 $rules_line .= " UPPER(".$key.")".$case;
	}
       else
	{
	 $rules_line .= " ".$key.$case;
	}
       $rules_line .= $r_value;
      }
    }
  }
 return($rules_line);
}

sub free
{
 my $self = shift;
 if($self->{'dbh'} and $self->{'mydbh'})
   {
     my $dbh = $self->{'dbh'};
     $dbh->disconnect();
   }
 my $key;
 foreach $key (keys %$self)
  {
   $self->{$key} = undef;
  }
 return(1);
}

sub DESTROY
{
  my $self = shift;
  if($self->{'dbh'} and $self->{'mydbh'})
    {
      my $dbh = $self->{'dbh'};
      $dbh->disconnect();
    }
  1;
}

# DO NOT EDIT "default_tables" hash, use your custom hash ref from new() function's parameter line!
$__PACKAGE__::default_tables = {};
$__PACKAGE__::default_tables->{'table_names'} = {'cat_name' => 'categories', 'item_name' => 'items', 'rcat_name' => 'rcats', 'ritem_name' => 'ritems'};
$__PACKAGE__::default_tables->{'select_columns'}   = 'ID,CID,NAME,VALUE,ENTERED,QUALIFIER';
$__PACKAGE__::default_tables->{'r_select_columns'} = 'UID,ID,RELATION,CAT_DEST,ITEM_DEST,QUALIFIER';
$__PACKAGE__::default_tables->{'tables'} = {$__PACKAGE__::default_tables->{'table_names'}->{'cat_name'} => 
  "CREATE TABLE %%name%%_".$__PACKAGE__::default_tables->{'table_names'}->{'cat_name'}."
    (
	ID      BIGINT(15) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	CID     BIGINT(15) UNSIGNED NOT NULL DEFAULT 0,
	NAME    VARCHAR(255) NOT NULL,
	VALUE   VARCHAR(255) BINARY NOT NULL,
	ENTERED TIMESTAMP(12),
	QUALIFIER VARCHAR(100) BINARY,
	INDEX   index_1 (CID),
	KEY     index_2 (NAME(4))
     )Type=MyISAM",
$__PACKAGE__::default_tables->{'table_names'}->{'item_name'} => 
  "CREATE TABLE %%name%%_".$__PACKAGE__::default_tables->{'table_names'}->{'item_name'}."
    (
	ID      BIGINT(15) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	CID     BIGINT(15) UNSIGNED NOT NULL DEFAULT 0,
	NAME    VARCHAR(255) NOT NULL,
	VALUE   VARCHAR(255) BINARY NOT NULL,
	ENTERED TIMESTAMP(12),
	QUALIFIER VARCHAR(100) BINARY,
	INDEX   index_1 (CID),
	KEY     index_2 (NAME(4)),
	KEY     index_3 (VALUE(3))
    )Type=MyISAM",
$__PACKAGE__::default_tables->{'table_names'}->{'rcat_name'} => 
  "CREATE TABLE %%name%%_".$__PACKAGE__::default_tables->{'table_names'}->{'rcat_name'}."
    (
	UID       BIGINT(15) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	ID        BIGINT(15) UNSIGNED NOT NULL,
	RELATION  VARCHAR(20) BINARY NOT NULL,
	CAT_DEST  BIGINT(15) UNSIGNED NOT NULL,
	ITEM_DEST BIGINT(15) UNSIGNED NOT NULL,
	QUALIFIER VARCHAR(100) BINARY,
	INDEX   index_1 (ID),
	KEY     index_2 (RELATION(10))
    )Type=MyISAM",
$__PACKAGE__::default_tables->{'table_names'}->{'ritem_name'} => 
  "CREATE TABLE %%name%%_".$__PACKAGE__::default_tables->{'table_names'}->{'ritem_name'}."
    (
	UID       BIGINT(15) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	ID        BIGINT(15) UNSIGNED NOT NULL,
	RELATION  VARCHAR(20) BINARY NOT NULL,
	CAT_DEST  BIGINT(15) UNSIGNED NOT NULL,
	ITEM_DEST BIGINT(15) UNSIGNED NOT NULL,
	QUALIFIER VARCHAR(100) BINARY,
	INDEX   index_1 (ID),
	KEY     index_2 (RELATION(10))
    )Type=MyISAM",
};

$__PACKAGE__::default_errors_messages = {
 # sub new
 '1.1' => "1.1:Can't load module DBI.pm",
 '1.2' => "1.2:Can't connect to database!",
 '1.3' => "1.3:Unrecognized",
 '1.4' => "1.4:Fail prepare() with SQL query: 'SHOW TABLES...'",
 '1.5' => "1.5:Fail execute() with SQL query: 'SHOW TABLES...'",
 '1.6' => "1.6:Can't create missing table!",
 # sub find
 '2.1' => "2.1:'Search' text is undefined!",
 '2.2' => "2.2:Database(table) structure is not available!",
 '2.3' => "2.3:Fail execute() with SQL query: 'SELECT FROM...' in ITEM sense",
 '2.4' => "2.4:Fail prepare() with SQL query: 'SELECT FROM...' in ITEM sense",
 '2.5' => "2.5:Fail execute() with SQL query: 'SELECT FROM...' in CATEGORIES sense",
 '2.6' => "2.6:Fail prepare() with SQL query: 'SELECT FROM...' in CATEGORIES sense",
 '2.7' => "2.7:Fail execute() with SQL query: 'SELECT FROM...' for ROUTE",
 '2.8' => "2.8:Fail prepare() with SQL query: 'SELECT FROM...' for ROUTE",
 '2.9' => "2.9:Database handler is 'undef'! Please connect to DB fisrt!",
 '2.10'=> "2.10:Unrecognized",
 # sub add
 '3.1' => "3.1:Can't ADD item/category with undefined name!",
 '3.2' => "3.2:Database(table) structure is not available!",
 '3.3' => "3.3:Unrecognized type!",
 '3.4' => "3.4:Add fault!",
 '3.5' => "3.5:Fail execute() with SQL query: 'INSERT INTO...'",
 '3.6' => "3.6:Fail prepare() with SQL query: 'INSERT INTO...'",
 # sub del
 '4.1' => "4.1:Can't DEL item/category with empty id!",
 '4.2' => "4.2:Database(table) structure is not available!",
 '4.5' => "4.5:Fail execute() with SQL query: 'DELETE FROM...'",
 '4.6' => "4.6:Fail prepare() with SQL query: 'DELETE FROM...'",
 '4.7' => "4.7:Fail execute() with SQL query: 'DELETE FROM...' in relate sense",
 '4.8' => "4.8:Fail prepare() with SQL query: 'DELETE FROM...' in relate sense",
 '4.11'=> "4.11:Unrecognized type!",
 '4.12'=> "4.12:Fail execute() with SQL query: 'SELECT FROM...'",
 '4.13'=> "4.13:Fail prepare() with SQL query: 'SELECT FROM...'",
 '4.14'=> "4.14:Fail execute() with SQL query: 'TRUNCATE TABLE...'",
 '4.15'=> "4.15:Fail prepare() with SQL query: 'TRUNCATE TABLE...'",
 # sub modify
 '5.1' => "5.1:Can't MODIFY item/category with empty id!",
 '5.2' => "5.2:Database(table) structure is not available!",
 '5.3' => "5.3:Unrecognized type!",
 '5.6' => "5.6:Fail execute() with SQL query: 'UPDATE SET...'",
 '5.7' => "5.7:Fail prepare() with SQL query: 'UPDATE SET...'",
 # sub traverse
 '6.1' => "6.1:Can't TRAVERSE item/category with undefined cid!",
 '6.2' => "6.2:Database(table) structure is not available!",
 '6.3' => "6.3:Fail rc_read_from_stream() with SQL 'SELECT FROM...'",
 '6.4' => "6.4:Can't write to swap(tmp) file!",
 '6.5' => "6.5:Can't create swap(tmp) file!",
 '6.6' => "6.6:Can't read from swap(tmp) file!",
 # sub deep_traverse
 '7.1' => "7.1:Fail execute() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '7.2' => "7.2:Fail prepare() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '7.3' => "7.3:Fail execute() with SQL query: 'SELECT FROM...' in ITEM sense",
 '7.4' => "7.4:Fail prepare() with SQL query: 'SELECT FROM...' in ITEM sense",
 # sub load_category
 '8.1' => "8.1:Fail execute() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '8.2' => "8.2:Fail prepare() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '8.3' => "8.3:Fail execute() with SQL query: 'SELECT FROM...' in ITEM sense",
 '8.4' => "8.4:Fail prepare() with SQL query: 'SELECT FROM...' in ITEM sense",
 # sub read
 '9.1' => "9.1:'Path' is empty!",
 '9.2' => "9.2:Database(table) structure is not available!",
 '9.3' => "9.3:Can't find part of category path! Please check you category tree!",
 '9.4' => "9.4:Fail execute() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '9.5' => "9.5:Fail prepare() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '9.6' => "9.6:Fail execute() with SQL query: 'SELECT FROM...' in ITEM sense",
 '9.7' => "9.7:Fail prepare() with SQL query: 'SELECT FROM...' in ITEM sense",
 '9.8' => "9.8:Database handler is 'undef'! Please connect to DB fisrt!",
 '9.9' => "9.9:Unrecognized",
 # sub r_add
 '10.1' => "10.1:Can't ADD relation without required ID's of objects!",
 '10.2' => "10.2:Can't ADD relation with empty relation field!",
 '10.3' => "10.3:Database(table) structure is not available!",
 '10.4' => "10.4:Unrecognized type!",
 '10.5' => "10.5:Relation add fault!",
 '10.6' => "10.6:Fail execute() with SQL query: 'INSERT INTO...'",
 '10.7' => "10.7:Fail prepare() with SQL query: 'INSERT INTO...'",
 # sub r_del
 '11.1' => "11.1:Database(table) structure is not available!",
 '11.2' => "11.2:Can't DEL relation with empty id and/or conditions!",
 '11.3' => "11.3:Fail execute() with SQL query: 'DELETE FROM...' in ITEM sense",
 '11.4' => "11.4:Fail prepare() with SQL query: 'DELETE FROM...' in ITEM sense",
 '11.5' => "11.5:Can't DEL relation with empty id and/or conditions!",
 '11.6' => "11.6:Fail execute() with SQL query: 'DELETE FROM...' in CATEGORY sense",
 '11.7' => "11.7:Fail prepare() with SQL query: 'DELETE FROM...' in CATEGORY sense",
 '11.8' => "11.8:Unrecognized type!",
 # sub r_find
 '12.1' => "12.1:'Search' text is undefined!",
 '12.2' => "12.2:Database(table) structure is not available!",
 '12.3' => "12.3:Fail execute() with SQL query: 'SELECT FROM...' in ITEM sense",
 '12.4' => "12.4:Fail prepare() with SQL query: 'SELECT FROM...' in ITEM sense",
 '12.5' => "12.5:Fail execute() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '12.6' => "12.6:Fail prepare() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '12.7' => "12.7:Database handler is 'undef'! Please connect to DB fisrt!",
 # sub r_modify
 '13.1' => "13.1:Can't MODIFY relation row with empty uid!",
 '13.2' => "13.2:Database(table) structure is not available!",
 '13.3' => "13.3:Unrecognized type!",
 '13.4' => "13.4:Fail execute() with SQL query: 'UPDATE SET...'",
 '13.5' => "13.5:Fail prepare() with SQL query: 'UPDATE SET...'",
 # sub is_tables_exists
 '14.1'=> "14.1:Fail prepare() with SQL query: 'SHOW TABLES...'",
 '14.2'=> "14.2:Fail execute() with SQL query: 'SHOW TABLES...'",
 '14.3'=> "14.3:Database handler is 'undef'! Please connect to DB fisrt!",
 # sub create_tables
 '15.1'=> "15.1:Fail prepare() with SQL query: 'SHOW TABLES...'",
 '15.2'=> "15.2:Fail execute() with SQL query: 'SHOW TABLES...'",
 '15.3'=> "15.3:Database handler is 'undef'! Please connect to DB fisrt!",
 '15.4'=> "15.4:Can't create missing table!",
 # sub lock_tables
 '16.1' => "16.1:Fail execute() with SQL query: 'LOCK TABLES...'",
 '16.2' => "16.2:Fail prepare() with SQL query: 'LOCK TABLES...'",
 '16.3' => "16.3:Fail execute() with SQL query: 'UNLOCK TABLES'",
 '16.4' => "16.4:Fail prepare() with SQL query: 'UNLOCK TABLES'",
 # sub show_names
 '17.1' => "17.1:Fail prepare() with SQL query: 'SHOW TABLES...'",
 '17.2' => "17.2:Fail execute() with SQL query: 'SHOW TABLES...'",
 '17.3' => "17.3:Database handler is 'undef'! Please connect to DB fisrt!",
 # sub r_list
 '18.1' => "18.1:'category' and 'item' id's are undefined!",
 '18.2' => "18.2:Database(table) structure is not available!",
 '18.3' => "18.3:Fail execute() with SQL query: 'SELECT FROM...' in ITEM sense",
 '18.4' => "18.4:Fail prepare() with SQL query: 'SELECT FROM...' in ITEM sense",
 '18.5' => "18.5:Fail execute() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '18.6' => "18.6:Fail prepare() with SQL query: 'SELECT FROM...' in CATEGORY sense",
 '18.7' => "18.7:Database handler is 'undef'! Please connect to DB fisrt!",
 };

1;
__END__

=head1 NAME

Related Categories - Create and process categories/items and relations within MySQL DB

=head1 VERSION

RCategories.pm ver.1.0

=head1 DESCRIPTION

=over 4

Related Categories allows you to create and process advanced categories for production sites/directories/shops,
user administrations, site administrations, configurations and etc...

=back

=head1 SYNOPSIS

 Here is a simple example (not complete yet), which you could use in your own CGI script:

 # --- Script begin here ---
 use RCategories;
 
 # You can use Mysql or DBD::Mysql (DBI) handlers
 # use Mysql;

 # NOTE: new() method will create needed DB structure in MySQL (database & tables) if they not exist!
 #       Please create database before execute this script or DB USER *must* have privilege to create DBs!
 
 # Or *ask* RCategories to connect DB for you.
 my $obj = RCategories->new(database => 'rcatsdb', user => 'db_user', pass => 'db_pass', host => 'localhost');
 
 # OR
 # $obj = RCategories->new(dbh => $mysql_dbi_handler);
 # DB handler should be created via DBI interface (for WebTools with mysql_dbi.pl driver),
 # however this module catch db handlers created via Mysql.pm (default mysql.pl driver).
 
 if($obj)
 {
   # Add some items and categories
   my $comp_id = $obj->add(type=>'category',name=>'Computers',category=>0,columns=>{'QUALIFIER'=>'Say What?'});
   my $film_id = $obj->add(type=>'category',name=>'Films',category=>0);
   my $matr_id = $obj->add(type=>'item',name=>'The Matrix',category=>$film_id,value=>'',columns=>{'QUALIFIER'=>'demo'});
   my $one_id  = $obj->add(type=>'item',name=>'The One',category=>$film_id,value=>'');
   my $cpu_id  = $obj->add(type=>'category',name=>'CPU',category=>$comp_id);
   my $hdd_id  = $obj->add(type=>'category',name=>'HDD',category=>$comp_id);
   my $ibm_id  = $obj->add(type=>'item',name=>'IBM ThinkPad',category=>$comp_id,value=>'');
   my $xp18_id = $obj->add(type=>'item',name=>'Athlon XP 1800+',category=>$cpu_id,value=>'');
   my $xp20_id = $obj->add(type=>'item',name=>'Athlon XP 2000+',category=>$cpu_id,value=>'');
   my $xp21_id = $obj->add(type=>'item',name=>'Athlon XP 2100+',category=>$cpu_id,value=>'');
   my $hdd1_id = $obj->add(type=>'item',name=>'Maxtor 80 GB',category=>$hdd_id,value=>'30 months warranty');
   my $hdd2_id = $obj->add(type=>'item',name=>'Maxtor 120 GB',category=>$hdd_id,value=>'36 months warranty');
   
   # Add some relations
   my $r_root_id = $obj->r_add(type=>'item',id=>$hdd1_id,cat_dest=>$hdd_id,relation=>'BEST BUY',columns=>{'QUALIFIER'=>'More info'});
   my $r_root_id = $obj->r_add(type=>'item',id=>$hdd1_id,item_dest=>$ibm_id,relation=>'STORAGE',columns=>{'QUALIFIER'=>'Another info'});
   my $r_root_id = $obj->r_add(type=>'category',id=>$hdd_id,item_dest=>$hdd1_id,relation=>'BEST AVAILABLE');
   my $r_cpu_id  = $obj->r_add(type=>'item',id=>$xp21_id,item_dest=>$ibm_id,relation=>'PART OF');
   
   my @res = $obj->read(path=>'//Computers//HDD//*',sort=>'ID',reverse=>NO,partial=>'YES','caseinsensitive'=>'Y');
   print "<HR>\n";
   #print $obj->error();
   if(!$obj->errorno())
     {
      foreach $l (@res)
       {
       	 # NOTE: $qualifier is additional field and you can have many like these.. just create your own DB structure
       	 #       but be careful, because you will need to add more variable in list below!
       	 my %inp = %$l;
         my ($type,$id,$parent_category,$name,$value,$qualifier,$route) =
            ($inp{'type'},$inp{'ID'},$inp{'CID'},$inp{'NAME'},$inp{'VALUE'},$inp{'QUALIFIER'},$inp{'route'});
         print "Type:   $type<BR>\n";
         print "ID:     $id<BR>\n";
         print "PARENT: $parent_category<BR>\n";
         print "NAME:   $name<BR>\n";
         print "VALUE:  $value<BR>\n";
         print "PATH:   ";
         my @path = @$route;
         my $p;
         foreach $p (@path)
          {
           print "\\".$p->{'NAME'};
          }
         print "<HR>\n";
       }
     }
   
   # New feature! This is ref to hash with additional rules applied in find routines (in r_find too).
   my $rules = {};
   $rules->{'QUALIFIER'}->{'caseinsensitive'} = 'Y';
   $rules->{'QUALIFIER'}->{'logic'} = 'AND';
   $rules->{'QUALIFIER'}->{'partial'} = 'Y';
   $rules->{'QUALIFIER'}->{'value'} = 'demo';
   $rules->{'QUALIFIER'}->{'like_pattern'} = 'left,right';
   #$rules->{'SOME'}->{'caseinsensitive'} = 'N';
   #$rules->{'SOME'}->{'logic'} = 'OR';
   #$rules->{'SOME'}->{'partial'} = 'Y';
   #$rules->{'SOME'}->{'value'} = 'some_value';
   #$rules->{'SOME'}->{'like_pattern'} = 'right';
   #$rules->{'_properties'}->{'columns_order'} = 'QUALIFIER,SOME';
   # This will produce follow "where-like" line: 
   # ...WHERE... AND UPPER(QUALIFIER) LIKE '%DEMO%' OR SOME LIKE 'some\_value%'
   
   @res = $obj->find('search'=>'The Matrix','sort'=>'ID','by'=>'NAME','filter'=>'ALL','multiple'=>'YES',
                     'route'=>'YES','partial'=>'NO','reverse'=>'NO','rules'=>$rules);
   if(!$obj->errorno())
     {
      foreach $l (@res)
       {
       	 # Take attantion of new $qualifier field...
       	 my %inp = %$l;
         my ($type,$id,$parent_category,$name,$value,$qualifier,$route) =
            ($inp{'type'},$inp{'ID'},$inp{'CID'},$inp{'NAME'},$inp{'VALUE'},$inp{'QUALIFIER'},$inp{'route'});
         print "Type:   $type<BR>\n";
         print "ID:     $id<BR>\n";
         print "PARENT: $parent_category<BR>\n";
         print "NAME:   $name<BR>\n";
         print "VALUE:  $value<BR>\n";
         print "PATH:   ";
         my @path = @$route;
         my $p;
         foreach $p (@path)
          {
           print "\\".$p->{'NAME'};
          }
         print "<BR>\n";
       }
     }
    print "<HR>\n";

    # Relation search by ITEM_DEST. You can use new parameter "rules" to specify additional
    # searching rules (as is in "find")!
    @res = $obj->r_find('search'=>$hdd_id,'by'=>'CAT_DEST','filter'=>'ALL','multiple'=>'YES',
                        'partial'=>'NO','reverse'=>'NO');
   if(!$obj->errorno())
     {
      foreach $l (@res)
       {
         my %inp = %$l;
         my ($type,$uid,$id,$relation,$cat,$item,$qualifier) =
            ($inp{'type'},$inp{'UID'},$inp{'ID'},$inp{'RELATION'},$inp{'CAT_DEST'},$inp{'ITEM_DEST'},$inp{'QUALIFIER'});
         print "Type:   $type<BR>\n";
         print "UID:    $uid<BR>\n";
         print "ID:     $id<BR>\n";
         print "TYPE:   $relation<BR>\n";
         print "CAT:    $cat<BR>\n";
         print "ITEM:   $item<BR>\n";
         print "QUALIFIER:  $qualifier<BR>\n";
       }
     }
    print "<HR>\n";
    
    # Modify: Change PARENT/CID and/or NAME
    $obj->modify(id=>$xp21_id,type=>'item',name=>'Duron 1300 MHz',value=>'',columns=>{'QUALIFIER'=>'Now is clear!?'});
    $obj->modify(id=>$comp_id,type=>'category',name=>'PC');
    $obj->modify(id=>$cpu_id,type=>'category',newcid=>0);
    $obj->modify(id=>$cpu_id,type=>'category',newid=>10);
    $obj->modify(id=>$xp21_id,type=>'item',newid=>1000);

    # Modify related item
    $obj->r_modify(uid=>$r_root_id,type=>'item',id=>$hdd2_id,newuid=>200,relation=>'WHATEVER',columns=>{'QUALIFIER'=>$hdd1_id});
    
    $obj->deep_traverse('id'=>0,'level'=>0,'path'=>'//','eval'=>\&Walk,'sort'=>'NAME','max_level'=>0);
    
    @res = $obj->load_category(cid=>'0', sort=>'NAME', reverse=>'N');

    if(!$obj->errorno())
     {
      foreach $l (@res)
       {
       	 my %inp = %$l;
         my ($type,$id,$parent_category,$name,$value,$qualifier) =
            ($inp{'type'},$inp{'ID'},$inp{'CID'},$inp{'NAME'},$inp{'VALUE'},$inp{'QUALIFIER'});
         print "Type:   $type<BR>\n";
         print "ID:     $id<BR>\n";
         print "PARENT: $parent_category<BR>\n";
         print "NAME:   $name<BR>\n";
         print "VALUE:  $value<BR>\n";
         print "QUALIFIER:  $qualifier<BR>\n";
       }
     }
    print "<HR>\n\n";
    
    @res = $obj->r_list('item'=>$hdd1_id,'filter'=>'CATEGORIES','reverse'=>'NO');
    if(!$obj->errorno())
     {
      foreach $l (@res)
       {
         my %inp = %$l;
         my ($type,$uid,$id,$relation,$cat,$item,$qualifier) =
            ($inp{'type'},$inp{'UID'},$inp{'ID'},$inp{'RELATION'},$inp{'CAT_DEST'},$inp{'ITEM_DEST'},$inp{'QUALIFIER'});
         print "Type:   $type<BR>\n";
         print "UID:    $uid<BR>\n";
         print "ID:     $id<BR>\n";
         print "TYPE:   $relation<BR>\n";
         print "CAT:    $cat<BR>\n";
         print "ITEM:   $item<BR>\n";
         print "QUALIFIER:  $qualifier<BR>\n";
       }
     }
    print "<HR>\n";
    
    # Delete ROOT category, so all items/categories are deleted!
    # Delete all cats/items BUT NO relations.
    #$obj->del(type=>'category',id=>0,'del_related'=>'N');
    
    # Delete absolutly everything, including items/cats and relations!
    $obj->del(type=>'category',id=>0);
    
    #$obj->r_del(type=>'item',id=>$r_root_id);
    #$obj->r_del(type=>'item',item_conditions=>" UID='$r_root_id'");
    #$obj->del(type=>'item',id=>$xp20_id);
    
    print "Available names:\n";
    foreach my $name ($obj->show_names())
     {
      print "$name\n";
     }
    print $obj->error();
 }
else
 {
  print "<BR><BR>Problem!?<BR>\n".$RCategories::error;
 }
 
sub Walk
 {
  my $self = shift;
  my %inp  = @_;
 
  my $id              = $inp{'id'};
  my $level           = $inp{'level'};
  my $separator       = $inp{'separator'};
  my $c		      = $inp{'columns'};
  
  my $path            = $c->{'route'};
  my @path = @$path;
  my $a;
  foreach $a (@path)
   {
    print "\\".$a->{'NAME'};
   }
  print "\\$name"."[".$c->{'VALUE'}." and ".$c->{'NAME'}."]<BR>\n";
 }
 # --- Script ends here ---

=head1 SYNTAX

 Function reference is provided separate (rcategories.html): not written yet.

=head1 AUTHOR

 Julian Lishev - Bulgaria,Sofia
 e-mail: julian@proscriptum.com

 Copyright (c) 2003, Julian Lishev, Sofia 2003
 All rights reserved.
 This file is legal part of WebTools module 
 maintained and distributed by www.proscriptum.com, 
 owned by Julian Lishev (julian@proscriptum.com).
 This code is NOT free software.
 For more information, read follow file:
 "docs/webtools_help/webtools_install.html"

=cut

################################################
# Module purposes:
# To create and manage advanced (related)
# categories within MySQL DB.
################################################

################################################
# Available methods:
# new(), is_tables_exists(), create_tables(),
# find(), add(), del(), modify(), traverse(),
# error(), errorno(), clear_error(), free(),
# deep_traverse(), load_category(), read(),
# show_names(), lock_tables()
# r_add(), r_del(), r_find(), r_modify(),
# r_list()
################################################
