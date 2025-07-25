#!perl

## Spell check as much as we can

use 5.008001;
use strict;
use warnings;
use Test::More;
use utf8; ## no critic (TooMuchCode::ProhibitUnnecessaryUTF8Pragma)
select(($|=1,select(STDERR),$|=1)[1]);

my (@testfiles, $fh);

if (! $ENV{AUTHOR_TESTING}) {
    plan (skip_all =>  'Test skipped unless environment variable AUTHOR_TESTING is set');
}
elsif (!eval { require Text::SpellChecker; 1 }) {
    plan skip_all => 'Could not find Text::SpellChecker';
}
else {
    opendir my $dir, 't' or die qq{Could not open directory 't': $!\n};
    @testfiles = map { "t/$_" } grep { ! /spellcheck|lint/ } grep { /^.+\.(t|pl)$/ } readdir $dir;
    closedir $dir or die qq{Could not closedir "$dir": $!\n};
    plan tests => 20+@testfiles;
}

my %okword;
while (<DATA>) {
    next if /^#/ or ! /\w/;
    for (split) {
        $okword{$_}++;
    }
}


sub spellcheck {
    my ($desc, $text, $filename) = @_;

    my $check = Text::SpellChecker->new(text => $text, lang => 'en_US');
    my %badword;
    while (my $word = $check->next_word) {
        next if $okword{$word};
        $badword{$word}++;
    }
    my $count = keys %badword;
    if (! $count) {
        pass ("Spell check passed for $desc");
        return;
    }
    fail ("Spell check failed for $desc. Bad words: $count");
    for (sort keys %badword) {
        diag "$_\n";
    }
    return;
}


## First, the plain ol' textfiles
for my $file (qw/README Changes TODO README.dev README.win32 CONTRIBUTING.md/) {

    if (!open $fh, '<', $file) {
        fail (qq{Could not find the file "$file"!});
    }
    else {
        binmode($fh, ':encoding(UTF-8)');
        { local $/; $_ = <$fh>; }
        close $fh or warn qq{Could not close "$file": $!\n};
        if ($file eq 'Changes') {
            ## Too many proper names to worry about here:
            s{\[.+?\]}{}gs;
            s{\b[Tt]hanks to (?:[A-Za-z]\w+\W){1,3}}{}gs;
            s{\bpatch from (?:[A-Z]\w+\W){1,3}}{}gs;
            s{\b[Rr]eported by (?:[A-Z]\w+\W){1,3}}{}gs;
            s{\breport from (?:[A-Z]\w+\W){1,3}}{}gs;
            s{\b[Ss]uggested by (?:[A-Z]\w+\W){1,3}}{}gs;
            s{\bSpotted by (?:[A-Z]\w+\W){1,3}}{}gs;

            ## Emails are not going to be in dictionaries either:
            s{<.+?>}{}gs;

        }
        elsif ($file eq 'README.dev') {
            s/^\t\$.+//gsm;
        }
        spellcheck ($file => $_, $file);
    }
}

## Now the embedded POD
SKIP: {
    if (!eval { require Pod::Spell; 1 }) {
        skip ('Need Pod::Spell to test the spelling of embedded POD', 2);
    }

    for my $file (qw{Pg.pm lib/Bundle/DBD/Pg.pm}) {
        if (! -e $file) {
            fail (qq{Could not find the file "$file"!});
        }
        my $string = qx{podspell $file};
        spellcheck ("POD from $file" => $string, $file);
    }
}

## Now the comments
SKIP: {
    if (!eval { require File::Comments; 1 }) {
        skip ('Need File::Comments to test the spelling inside comments', 12+@testfiles);
    }
    {
        ## For XS files...
        package File::Comments::Plugin::Catchall; ## no critic
        use strict;
        use warnings;
        require File::Comments::Plugin;
        require File::Comments::Plugin::C;

        our @ISA     = qw(File::Comments::Plugin::C);

        sub applicable {
            return 1;
        }
    }


    my $fc = File::Comments->new();

    my @files;
    for (sort @testfiles) {
        push @files, "$_";
    }


    for my $file (@testfiles, qw{Makefile.PL Pg.xs Pg.pm lib/Bundle/DBD/Pg.pm
        dbdimp.c dbdimp.h types.c quote.c quote.h Pg.h types.h dbdpg_test_postgres_versions.pl}) {
        ## Tests as well?
        if (! -e $file) {
            fail (qq{Could not find the file "$file"!});
        }
        my $string = $fc->comments($file);
        if (! $string) {
            fail (qq{Could not get comments from file $file});
            next;
        }
        $string = join "\n" => @$string;
        $string =~ s/=head1.+//sm;
        spellcheck ("comments from $file" => $string, $file);
    }


}


__DATA__
## These words are okay

abc
ABCD
ActiveKids
adbin
adsrc
AIX
alphanum
archlib
arg
arith
arrayout
arrayref
arrayrefs
ArrayTupleFetch
ASC
async
ASYNC
attr
attrib
attribs
authtype
autocommit
AutoCommit
autodie
AutoEscape
Autogenerate
AutoInactiveDestroy
AvARRAY
Backcountry
backend
backend's
backslashed
backtrace
basename
BegunWork
bigint
BIGINT
bitmask
blib
BMP
bool
boolean
booleans
boolout
bools
bpchar
bt
bucardo
BUFSIZE
Bunce
bytea
Bytea
BYTEA
CachedKids
CamelCase
cancelled
CARDINALITY
carlos
cd
checksums
Checksums
ChildHandles
chopblanks
ChopBlanks
chr
cid
CMD
cmd
cmdtaglist
cmp
compat
CompatMode
conf
config
conformant
consrc
Conway's
copydata
COPYing
copypv
copystate
coredump
coredumps
Coredumps
cpan
CPAN
cpansearch
cpantesters
cperl
currph
currpos
CursorName
cvs
cx
dashdash
dat
datatype
Datatype
DATEOID
datetime
david
dbd
DBD
dbdimp
dbdpg
DBDPG
dbgpg
dbh
dbi
DBI
DBIc
DBICTEST
DBILOGFP
DBIS
dbivport
dbix
DBIx
DBIXS
dbmethod
dbname
DDL
deallocate
Deallocate
DEALLOCATE
deallocating
deallocation
Deallocation
Debian
decls
Deepcopy
defaultval
DefaultValue
delim
dequote
dequoting
dereference
descr
DESCR
destringify
destringifying
dev
devel
Devel
dHTR
dir
dirname
discon
distcheck
disttest
DML
dollaronly
dollarquote
dollarsign
dollarstring
downcase
DProf
dprofpp
dq
dr
drh
DRV
DSN
dTHX
dv
DynaLoader
eg
el
elsif
emacs
endcopy
EnterpriseDB
enum
env
ENV
ErrCount
errorlevel
errstr
estring
eval
exe
ExecStatusType
externs
EXTRALIBS
ExtUtils
fallthrough
fe
fetchall
FetchHashKeyName
fetchrow
fh
filename
firstword
fk
fprintf
FreeBSD
fulltest
func
funcs
funct
gborg
GBorg
gcc
gdb
ge
getcom
getcopydata
getfd
getline
Gf
GF
GH
github
Github
gmx
gotlist
goto
GPG
gpl
GPL
greg
gz
HandleError
HandleSetErr
hashref
hashrefs
hstore
html
http
https
ifdefs
implementor
InactiveDestroy
IncludingOptionalDependencies
inerror
initdb
inout
installarchlib
installsitearch
intra
ints
INV
IP
IRC
irc
ish
ITHREADS
json
JSON
jsonb
jsontable
Kbytes
kwlist
largeobject
largeobjects
lc
ld
LD
leaktester
LEFTARG
len
libera
libpg
libpq
linux
LOBs
localhost
localtime
login
LongReadLen
LongTruncOk
LONGVARCHAR
lotest
lpq
lseg
LSEG
lsegs
lssl
lt
mak
Makefile
MAKEFILE
MakeMaker
malloc
maxlen
MCPAN
md
MDevel
Mergl
metadata
minversion
mis
mkdir
Momjian
mortalize
msg
MSVC
Mullane
multi
Multi
MULTI
mv
MYMETA
myperl
myval
Compiled
ndone
ne
ness
newfh
newSVpv
Newz
nmake
nohead
nonliteral
noprefix
noreturn
nosetup
NOSUCH
Server
nullable
NULLABLE
NULLs
num
NUM
numbound
numphs
numrows
NYTProf
nytprofhtml
ocitrace
oct
ODBC
odbcversion
ODBCVERSION
ofile
oid
Oid
OID
oids
OIDS
ok
oldfh
OLDQUERY
onerow
onwards
optimizations
param
params
PARAMS
ParamTypes
ParamValues
parens
ParseData
ParseHeader
PASSBYVAL
passwd
pc
pch
perl
perlcritic
perlcriticrc
perldocs
Perlish
perls
PGBOOLOID
pgbouncer
PgBouncer
pgBouncer
PGCLIENTENCODING
PGDATABASE
pgend
PGfooBar
PGINITDB
pglibpq
pglogin
pgp
PGPORT
pgprefix
PGRES
PGresult
PGSERVICE
PGSERVICEFILE
pgsql
pgstart
PGSYSCONFDIR
pgtype
pgver
ph
php
pid
PID
pos
POSIX
postgres
Postgres
POSTGRES
postgresdir
postgresql
PostgreSQL
postgresteam
powf
PQ
PQchangePassword
PQclear
PQclosePrepared
PQconnectdb
PQconsumeInput
PQexec
PQexecParams
PQexecPrepared
PQoids
PQprepare
PQprotocolVersion
PQresultErrorField
PQsend
PQsendQuery
PQsendQueryParams
PQsendQueryPrepared
PQserverVersion
PQsetErrorVerbosity
PQsetSingleRowMode
PQstatus
pqtype
PQvals
pragma
pragmas
pre
preparable
preparse
preparser
prepending
preprocessors
prereqs
PrintError
printf
PrintWarn
profiler
projdisplay
proven
pseudotype
pulldown
putcopydata
putcopyend
putline
pv
pwd
PYTHIAN
qq
qual
quickexec
qw
Rainer
RaiseError
rc
RDBMS
README
ReadOnly
realclean
recv'd
Refactor
regex
reinstalling
relcheck
relkind
reltuples
repo
reprepare
repreparing
RequireUseWarnings
requote
rescan
resultset
RIGHTARG
ROK
RowCache
RowCacheSize
RowsInCache
rowtypes
Sabino
safemalloc
savepoint
savepoints
Savepoints
schemas
scs
scsys
sectionstop
selectall
selectcol
selectrow
sha
shortid
ShowErrorStatement
sitearch
skipcheck
slashstar
SMALLINT
smethod
snprintf
Solaris
spclocation
spellcheck
sprintf
sql
SQL
sqlc
sqlclient
sqlstate
SQLSTATE
sqltype
src
SSL
sslmode
starslash
StartTransactionCommand
stderr
STDERR
STDIN
STDOUT
sth
strcmp
strcpy
strdup
stringifiable
stringification
stringify
strlen
STRLEN
strncpy
strtod
struct
structs
subdirectory
submitnews
substr
sv
Sv
SV
svn
SvNVs
SvPV
SVs
SvTRUE
svtype
SvUTF
SYS
tableinfo
tablename
tablespace
tablespaces
TaintIn
TaintOut
Tammer
tcop
TCP
tempfile
testdatabase
testfile
testme
testname
textout
tf
THEADER
thisname
tid
TID
TIMEOID
timestamp
TIMESTAMP
timestamptz
TIMESTAMPTZ
TINYINT
tmp
TMP
TODO
topav
topdollar
TraceLevel
TSQUERY
tty
tuple
tuples
TUPLES
turnstep
txn
txt
typarray
typdelim
typedef
typefile
typelem
typename
typinput
typname
typoutput
typrecv
typrelid
typsend
Ubuntu
uc
uid
uk
undef
undefs
unescaped
unicode
UNKNOWNOID
untrace
userid
username
Username
usr
utf
UTF
Util
valgrind
vals
VARBINARY
varchar
VARCHAR
VARCHAROID
Vc
VC
vcvars
VER
versa
versioning
veryverylongplaceholdername
Waggregate
Wbad
Wcast
Wchar
Wcomment
Wconversion
Wdisabled
weeklynews
Wendif
Wextra
wfile
Wfloat
Wformat
whitespace
Wimplicit
Winit
Winline
Winvalid
Wmain
Wmissing
Wnested
Wnonnull
Wpacked
Wpadded
Wparentheses
Wpointer
Wredundant
Wreturn
writeable
Wsequence
Wshadow
Wsign
Wstrict
Wswitch
Wsystem
Wtraditional
Wtrigraphs
Wundef
Wuninitialized
Wunknown
Wunreachable
Wunused
Wwrite
www
xcopy
xPID
xs
xsi
XSLoader
xst
XSubPPtmpAAAA
xxh
yaml
YAML
YAMLiciousness
yml
