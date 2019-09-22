use v6;
use Test;

use XML::Actions::Stream;

#-------------------------------------------------------------------------------
my $dir = 't/x';
mkdir $dir unless $dir.IO ~~ :e;
my Str $file = "$dir/a.xml";

#-------------------------------------------------------------------------------
class A is XML::Actions::Stream::Work {

  has Bool $.doctype = False;

  multi method xml:doctype (
    :$empty!, :$public!, :$fpi!, :$url!, :$dtd!
  ) {
    $!doctype = True;
    ok !$empty, 'dtd has content';
    is $url, "spec.dtd", 'url found';
    is $fpi, "abc//def//pqr", "fpi found";
    like $dtd, / '<!ELEMENT someElement (#PCDATA)>' /, 'dtd text found';
  }

  multi method xml:doctype (
    :$empty!, :$system!, :$url!, :$dtd!
  ) {
    $!doctype = True;
    ok !$empty, 'dtd has content';
    is $url, "spec.dtd", 'url found';
    like $dtd, / '<!ELEMENT someElement (#PCDATA)>' /, 'dtd text found';
  }

  multi method xml:doctype ( :$empty!, :$system!, :$url! ) {
    $!doctype = True;
    ok !$empty, 'dtd has content';
    is $url, "spec.dtd", 'url found';
  }

  multi method xml:doctype ( :$empty!, :$dtd! ) {
    $!doctype = True;
    ok !$empty, 'dtd has content';
    like $dtd, / '<!ELEMENT someElement (#PCDATA)>' /, 'dtd text found';
  }

  multi method xml:doctype ( :$empty!, :$root-element ) {
    $!doctype = True;
    ok $empty, 'dtd has no content';
    is $root-element, 'someElement', 'Root element is <someElement>';
  }
}

#-------------------------------------------------------------------------------
subtest 'Action object 1', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <!DOCTYPE someElement [
      <!ELEMENT someElement (#PCDATA)>
    ]>
    <someElement></someElement>
    EOXML

  my XML::Actions::Stream $a .= new(:$file);
  isa-ok $a, XML::Actions::Stream, 'type ok';

  my A $w .= new();
  $a.process(:actions($w));
  ok $w.doctype, 'doctype seen';
}

#-------------------------------------------------------------------------------
subtest 'Action object 2', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <!DOCTYPE someElement SYSTEM "spec.dtd">
    <someElement></someElement>
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  $a.process(:actions($w));
  ok $w.doctype, 'doctype seen';
}

#-------------------------------------------------------------------------------
subtest 'Action object 3', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <!DOCTYPE someElement SYSTEM "spec.dtd" [
      <!ELEMENT someElement (#PCDATA)>
    ]>
    <someElement></someElement>
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  $a.process(:actions($w));
  ok $w.doctype, 'doctype seen';
}

#-------------------------------------------------------------------------------
subtest 'Action object 4', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <!DOCTYPE someElement PUBLIC "abc//def//pqr" "spec.dtd" [
      <!ELEMENT someElement (#PCDATA)>
    ]>
    <someElement></someElement>
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  $a.process(:actions($w));
  ok $w.doctype, 'doctype seen';
}

#-------------------------------------------------------------------------------
subtest 'Action object 5', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <!DOCTYPE someElement>
    <someElement></someElement>
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  $a.process(:actions($w));
  ok $w.doctype, 'doctype seen';
}

#-------------------------------------------------------------------------------
done-testing;

unlink $file;
rmdir $dir;
