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
      tada1
      <xyz:element name="State" type="string" minOccurs="0">
        xyz
      </xyz:element>
      tadaaaa2
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
#note "complexType; '", $parent-path[*-1].contents.join("', '"), "'";
  }

  method all:start ( Array $parent-path, :$name ) {
    is $parent-path[*-1].name, 'all', '<all>';
    $!all-seen = True;
#for $parent-path[*-1].contents -> $txt { say "'$txt'"; }
  }

  method all-END ( Array $parent-path, :$name ) {
    is $parent-path[*-1].name, 'all', '</all>';
    $!all-seen = True;
  }

  method complexType-END ( Array $parent-path ) {
    is $parent-path[*-1].name, 'complexType', '</complexType>';
  }

  method xyz:element:start ( Array $parent-path ) {
    is $parent-path[*-1].name, 'xyz:element', 'start ' ~ $parent-path[*-1].name;
#note "xyz:element; '", $parent-path[*-1].contents.join("', '"), "'";
  }

  method xyz:element:end ( Array $parent-path ) {
    is $parent-path[*-1].name, 'xyz:element', 'end ' ~ $parent-path[*-1].name;
  }

  method xml:text ( Array $parent-path, Str $text is copy ) {
    next if $text ~~ m/^ \s* $/;
    $text ~~ s/^ \s+ //;
    $text ~~ s/ \s+ $//;
#note 'PP: ', $parent-path[*-1].name, ', ', $text;
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
