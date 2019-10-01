use v6;
use Test;

use XML::Actions::Stream;

#-------------------------------------------------------------------------------
my $dir = 't/x';
mkdir $dir unless $dir.IO ~~ :e;

my Str $file = "$dir/a.xml";
$file.IO.spurt(Q:q:to/EOXML/);
  <?xml version='1.0'?>
  <!DOCTYPE scxml [

    <!--define the internal DTD-->
    <!ELEMENT scxml (#PCDATA)>
    <!--close the DOCTYPE declaration-->
  ]>
  <scxml xmlns="http://www.w3.org/2005/07/scxml"
         version="1.0"
         initial="hello">

    <tst>text in tst</tst>
    <final id="hello">
      <onentry>
        <log expr="'hello world'" />
      </onentry>
    </final>
  </scxml>
  EOXML

#-------------------------------------------------------------------------------
class A is XML::Actions::Stream::Work {

  has Bool $.log-done = False;
  has Bool $.startend = False;
  has Bool $.prolog = False;
  has Bool $.doctype = False;

  method xml:prolog ( :$version ) {
    $!prolog = True;
    is $version, '1.0', 'xml version 1.0';
  }

  method xml:doctype ( :$dtd ) {
    $!doctype = True;
    like $dtd, /:s define the internal DTD/, 'dtd text found';
  }

  method final:start ( Array $parent-path, :$id ) {
#note $parent-path[*-1].value;
    is $id, 'hello', "final called: id = $id";
    is $parent-path[*-1].key, 'final', 'this node is final';
    is $parent-path[*-2].key, 'scxml', 'parent node is scxml';
  }

  method onentry:start ( Array $parent-path ) {
    is $parent-path[*-1].key, 'onentry', 'this node is onentry';
    is $parent-path[*-2].key, 'final', 'parent node is final';
    is $parent-path[*-3].key, 'scxml', 'parent parents node is scxml';
    is-deeply @$parent-path.map(*.key), <scxml final onentry>,
              "<scxml final onentry> found in parent array";
  }

  method onentry:end ( Array $parent-path ) {
    is $parent-path[*-1].key, 'onentry',
       'this node is onentry after processing children';
  }

  method scxml:end ( Array $parent-path ) {
    is $parent-path[*-1].key, 'scxml', 'end of scxml';
  }

  method log:start ( Array $parent-path, :$startend, :$expr ) {
    is $expr, "'hello world'", "log called: expr = $expr";
    is-deeply @$parent-path.map(*.key), <scxml final onentry log>,
              "<scxml final onentry log> found in parent array";

    ok $startend, '<log .../>';
    $!log-done = True;
  }

  method log:startend ( Array $parent-path, :$expr ) {
    $!startend = True;
  }
}

#`{{
#-------------------------------------------------------------------------------
subtest 'Action primitives', {
  my XML::Actions $a;

  throws-like
    { $a .= new(:file<non-existent-file>); },
    X::XML::Actions, message => "File 'non-existent-file' not found";

  throws-like
    { $a .= new(); $a.process(:actions(A.new())); },
    X::XML::Actions, message => "No xml document to work on";
}
}}

#-------------------------------------------------------------------------------
subtest 'Action object', {
  my XML::Actions::Stream $a .= new(:$file);
  isa-ok $a, XML::Actions::Stream, 'type ok';

  my A $w .= new();
  $a.process(:actions($w));
  ok $w.prolog, 'prolog seen';
  ok $w.doctype, 'doctype seen';
  ok $w.log-done, 'logging done';
  ok $w.startend, 'selfclosing seen';

#`{{ Cannot compare comlete string because attribs may change order
  note $a.result;
  is $a.result, '<?xml version="1.0"?><scxml xmlns="http://www.w3.org/2005/07/scxml" initial="hello" version="1.0"> <final id="hello"> <onentry> <log expr="&#39;hello world&#39;"/>  </onentry>  </final>  </scxml>', 'returned result ok';
}}
}

#-------------------------------------------------------------------------------
done-testing;

unlink $file;
rmdir $dir;
