use v6;
use Bench;

use XML::Actions;
use XML::Actions::Stream;

#-------------------------------------------------------------------------------
unit class BenchProgram;

my Str $file;
my Str $dir;

#-------------------------------------------------------------------------------
method prepare-test ( ) {

  # prepare document
  $dir = 'xt/x';
  mkdir $dir unless $dir.IO ~~ :e;
  $file = "$dir/a.xml";

  $file.IO.spurt(Q:q:to/EOXML/);
  <?xml version='1.0'?>
  <!DOCTYPE someElement [ <!ELEMENT someElement (#PCDATA)> > ]>
  <someElement>
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
    <someOtherElement1 attr1="val1" attr2="val2"> some text </someOtherElement1>
    <someOtherElement2 attr3="val3" attr4="val4" />
  </someElement>
  EOXML
}

#-------------------------------------------------------------------------------
# prepare classes with handlers
class ProcElems1 is XML::Actions::Work {
  has Int $.start-count = 0;
  has Int $.end-count = 0;
  method someElement:start ( Array $parent-path, *%attrs ) { $!start-count++ }
  method someOtherElement1:start ( Array $parent-path, *%attrs ) { $!start-count++ }
  method someOtherElement2:start ( Array $parent-path, *%attrs ) { $!start-count++ }
  method someElement:end ( Array $parent-path, *%attrs ) {  $!end-count++ }
  method someOtherElement1:end ( Array $parent-path, *%attrs ) { $!end-count++ }
  method someOtherElement2:end ( Array $parent-path, *%attrs ) { $!end-count++ }
}

class ProcElems2 is XML::Actions::Stream::Work {
  has Int $.start-count = 0;
  has Int $.end-count = 0;
  method someElement:start ( Array $parent-path, *%attrs ) { $!start-count++ }
  method someElement1:start ( Array $parent-path, *%attrs ) { $!start-count++ }
  method someElement2:start ( Array $parent-path, *%attrs ) { $!start-count++ }
  method someElement:end ( Array $parent-path, *%attrs ) { $!end-count++ }
  method someElement1:end ( Array $parent-path, *%attrs ) { $!end-count++ }
  method someElement2:end ( Array $parent-path, *%attrs ) { $!end-count++ }
}

#-------------------------------------------------------------------------------
method test-data0 ( --> Hash ) {
  %( :class-name<XML::Actions>,
     :sub-name<process>,
     :version<0.4.3>,
     :note('start'),
  )
}

#-------------------------------------------------------------------------------
method run-test0 ( ) {
  my XML::Actions $a .= new(:$file);
  my ProcElems1 $w .= new;
  $a.process(:actions($w));
}

#-------------------------------------------------------------------------------
method test-data1 ( --> Hash ) {
  %( :class-name<XML::Actions::Stream>,
     :sub-name<process>,
     :version<0.4.3>,
     :note('Change in detecting start of element'),
  )
}

#-------------------------------------------------------------------------------
method run-test1 ( ) {
  my XML::Actions::Stream $a .= new(:$file);
  my ProcElems2 $w .= new;
  $a.process(:actions($w));
}

#-------------------------------------------------------------------------------
method cleanup-test ( ) {
  unlink $file;
  rmdir $dir;
}


=finish
#$sbm.store-bench( Bench.new.timeit( $count, $test-part1),
#  :class-name('XML::Actions::Work'),
#  :version('0.4.2')
#);


# prepare class with handlers
class ProcElems2 is XML::Actions::Stream::Work {
  has Int $.start-count = 0;
  has Int $.end-count = 0;
  method someElement:start ( Array $parent-path, *%attrs ) { $!start-count++ }
  method someElement1:start ( Array $parent-path, *%attrs ) { $!start-count++ }
  method someElement2:start ( Array $parent-path, *%attrs ) { $!start-count++ }
  method someElement:end ( Array $parent-path, *%attrs ) { $!end-count++ }
  method someElement1:end ( Array $parent-path, *%attrs ) { $!end-count++ }
  method someElement2:end ( Array $parent-path, *%attrs ) { $!end-count++ }
}

my $test-part2 = sub {
  my XML::Actions::Stream $a .= new(:$file);
  my ProcElems2 $w .= new;
  $a.process(:actions($w));
}

$sbm.store-bench( Bench.new.timeit( $count, $test-part2),
  :class-name('XML::Actions::Stream::Work'),
  :version('0.4.2')
);
}}
