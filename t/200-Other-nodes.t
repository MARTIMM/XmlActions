use XML::Actions;
use Test;

#-------------------------------------------------------------------------------
my $dir = 't/x';
mkdir $dir unless $dir.IO ~~ :e;

my Str $file = "$dir/a.xml";
$file.IO.spurt(Q:q:to/EOXML/);
  <html>
    <body>
      <h1>Test for text</h1>
      <!-- Test for comment -->
      <![CDATA[ Test for CDATA]]>
      <?PITarget Test for PI?>
    </body>
  </html>
  EOXML

#-------------------------------------------------------------------------------
class A1 is XML::Actions::Work {
  has Int $.tests = 0;

  method xml:text ( Array $parent-path, Str $text ) {
    return if $text ~~ /^ \s* $/;
    is $text, 'Test for text', "Text '$text' found";
    is $parent-path[*-1].name, 'h1', 'parent node is h1';
    $!tests += 2;
  }

  method xml:comment ( Array $parent-path, Str $comment ) {
    is $comment, ' Test for comment ', "Text '$comment' found";
    is $parent-path[*-1].name, 'body', 'parent node is body';
    $!tests += 2;
  }

  method xml:cdata ( Array $parent-path, Str $cdata ) {
    is $cdata, ' Test for CDATA', "Text '$cdata' found";
    is $parent-path[*-1].name, 'body', 'parent node is body';
    $!tests += 2;
  }

  method xml:pi ( Array $parent-path, Str $pi-target, Str $pi-content ) {
    is $pi-target, 'PITarget', "Target '$pi-target' found";
    is $pi-content, 'Test for PI', "Text '$pi-content' found";
    is $parent-path[*-1].name, 'body', 'parent node is body';
    $!tests += 3;
  }
}

#-------------------------------------------------------------------------------
subtest 'Actions on object 1', {

  my XML::Actions $a .= new(:$file);
  isa-ok $a, XML::Actions, 'type ok';

  my A1 $w1 .= new();
  $a.process(:actions($w1));
  is $w1.tests, 9, 'nbr tests ok';
}

#-------------------------------------------------------------------------------
done-testing;

unlink $file;
rmdir $dir;
