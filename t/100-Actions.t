use XML::Actions;
use Test;

#-------------------------------------------------------------------------------
my $dir = 't/x';
mkdir $dir unless $dir.IO ~~ :e;

my Str $file = "$dir/a.xml";
my Str $xml = Q:q:to/EOXML/;
  <scxml xmlns="http://www.w3.org/2005/07/scxml"
         version="1.0"
         initial="hello">

    <final id="hello">
      <onentry>
        <log expr="'hello world'" />
      </onentry>
    </final>
  </scxml>
  EOXML

$file.IO.spurt($xml);

#-------------------------------------------------------------------------------
class A is XML::Actions::Work {

  has Bool $.log-done = False;

  # test if readable attribute is in the way of node names
  has Str $.log;

  method final:start ( Array $parent-path, :$id ) {
    is $id, 'hello', "final called: id = $id";
    is $parent-path[*-1].name, 'final', 'this node is final';
    is $parent-path[*-2].name, 'scxml', 'parent node is scxml';
  }

  method onentry:start ( Array $parent-path ) {
    is $parent-path[*-1].name, 'onentry', 'this node is onentry';
    is $parent-path[*-2].name, 'final', 'parent node is final';
    is $parent-path[*-3].name, 'scxml', 'parent parents node is scxml';
    is-deeply @$parent-path.map(*.name), <scxml final onentry>,
              "<scxml final onentry> found in parent array";
  }

  method onentry:end ( Array $parent-path ) {
    is $parent-path[*-1].name, 'onentry',
       'this node is onentry after processing children';
  }

  method log:start ( Array $parent-path, :$expr ) {
    is $expr, "'hello world'", "log called: expr = $expr";
    is-deeply @$parent-path.map(*.name), <scxml final onentry log>,
              "<scxml final onentry log> found in parent array";

    $!log-done = True;
    $!log = 'ok';
  }
}

#-------------------------------------------------------------------------------
class B is XML::Actions::Work {

  has Bool $.log-done = False;

  # test if readable attribute is in the way of node names
  has Str $.log = 'not ok';

  method final:start ( Array $parent-path, :$id --> ActionResult ) {
    is $id, 'hello', "final called: id = $id";
    is $parent-path[*-1].name, 'final', 'this node is final';
    is $parent-path[*-2].name, 'scxml', 'parent node is scxml';

    Truncate
  }

  # Because final above request to Truncate this method will not
  # be called and therefore variables are not changed
  method log:start ( Array $parent-path, :$expr ) {
    is $expr, "'hello world'", "log called: expr = $expr";
    is-deeply @$parent-path.map(*.name), <scxml final onentry log>,
              "<scxml final onentry log> found in parent array";

    $!log-done = True;
    $!log = 'ok';
  }
}

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

#-------------------------------------------------------------------------------
subtest 'Action object from file', {
  my XML::Actions $a .= new(:$file);
#  isa-ok $a, XML::Actions, 'type ok';

  my A $actions .= new();
  $a.process(:$actions);
  ok $actions.log-done, 'logging done: ' ~ $actions.log;

#`{{ Cannot compare comlete string because attribs may change order
  note $a.result;
  is $a.result, '<?xml version="1.0"?><scxml xmlns="http://www.w3.org/2005/07/scxml" initial="hello" version="1.0"> <final id="hello"> <onentry> <log expr="&#39;hello world&#39;"/>  </onentry>  </final>  </scxml>', 'returned result ok';
}}
}

#-------------------------------------------------------------------------------
subtest 'Actions returning Truncate', {
  my XML::Actions $a .= new(:$file);
  my B $actions .= new();
  $a.process(:$actions);
  nok $actions.log-done, 'logging not done: ' ~ $actions.log;
}

#-------------------------------------------------------------------------------
subtest 'Action object from string', {
  my XML::Actions $a .= new(:$xml);
#  isa-ok $a, XML::Actions, 'type ok';

  my A $actions .= new();
  $a.process(:$actions);
  ok $actions.log-done, 'logging done: ' ~ $actions.log;

#`{{ Cannot compare comlete string because attribs may change order
  note $a.result;
  is $a.result, '<?xml version="1.0"?><scxml xmlns="http://www.w3.org/2005/07/scxml" initial="hello" version="1.0"> <final id="hello"> <onentry> <log expr="&#39;hello world&#39;"/>  </onentry>  </final>  </scxml>', 'returned result ok';
}}
}

#-------------------------------------------------------------------------------
done-testing;

unlink $file;
rmdir $dir;
