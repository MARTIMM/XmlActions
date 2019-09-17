use v6;

use XML::Actions;
use Test;

#-------------------------------------------------------------------------------
my $dir = 't/x';
mkdir $dir unless $dir.IO ~~ :e;

my Str $file = "$dir/a.xml";
$file.IO.spurt(Q:q:to/EOXML/);
  <complexType name="ShipsFromType">
    <all>
      <xyz:element name="State" type="string" minOccurs="0">
        xyz
      </xyz:element>
      <xyz:element name="Country" type="string" minOccurs="0"/>
    </all>
  </complexType>
  EOXML

#-------------------------------------------------------------------------------
class A is XML::Actions::Work {
  has Bool $.all-seen = False;

  method complexType ( Array $parent-path, :$name ) {
    is $parent-path[*-1].name, 'complexType',
      ([~] "<", $parent-path[*-1].name, " name='$name'>");
  }

  method all:start ( Array $parent-path, :$name ) {
    is $parent-path[*-1].name, 'all', '<all>';
    $!all-seen = True;
  }

  method all-END ( Array $parent-path, :$name ) {
    is $parent-path[*-1].name, 'all', '</all>';
    $!all-seen = True;
  }

  method complexType-END ( Array $parent-path ) {
    is $parent-path[*-1].name, 'complexType', '</complexType>';
  }

  method xyz:element:start ( Array $parent-path, ) {
    is $parent-path[*-1].name, 'xyz:element', 'start ' ~ $parent-path[*-1].name;
  }

  method xyz:element:end ( Array $parent-path, ) {
    is $parent-path[*-1].name, 'xyz:element', 'end ' ~ $parent-path[*-1].name;
  }
}

#-------------------------------------------------------------------------------
subtest 'Action object', {
  my XML::Actions $a .= new(:$file);
  isa-ok $a, XML::Actions, '.new(:file)';

  my A $w .= new();
  $a.process(:actions($w));
  ok $w.all-seen, 'element <all> seen';
}

#-------------------------------------------------------------------------------
done-testing;

unlink $file;
rmdir $dir;
