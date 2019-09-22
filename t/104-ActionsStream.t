use v6;
use Test;

use XML::Actions::Stream;

#-------------------------------------------------------------------------------
my $dir = 't/x';
mkdir $dir unless $dir.IO ~~ :e;
my Str $file = "$dir/a.xml";

#-------------------------------------------------------------------------------
class A is XML::Actions::Stream::Work {

  method xml:doctype ( :$empty ) { }
}

#-------------------------------------------------------------------------------
subtest 'check doctype 1', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <!DOCTYPE someElement [
      <!ELEMENT someElement (#PCDATA)>
    >
    <someElement></someElement>
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  throws-like(
    { $a.process(:actions($w)); },
    X::XML::Actions::Stream, 'doctype DTD not ended properly',
    :message(/:s Parsing error/)
  );
}

#-------------------------------------------------------------------------------
subtest 'check doctype 2', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <!DOCTYPE someElement>
    <someElementX />
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  throws-like(
    { $a.process(:actions($w)); },
    X::XML::Actions::Stream, 'wrong root element',
    :message(/:s root element someElementX is not someElement from DTD/)
  );
}

#-------------------------------------------------------------------------------
subtest 'check doctype 3', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <someElement />
    <!DOCTYPE someElement>
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  throws-like(
    { $a.process(:actions($w)); },
    X::XML::Actions::Stream, 'wrong doctype location',
    :message(/:s Doctype at wrong place/)
  );
}

#-------------------------------------------------------------------------------
subtest 'check doctype 4', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <!DOCTYPE someElement>
    <!DOCTYPE someElement>
    <someElement />
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  throws-like(
    { $a.process(:actions($w)); },
    X::XML::Actions::Stream, 'Second doctype forbidden',
    :message(/:s Second doctype forbidden/)
  );
}

#-------------------------------------------------------------------------------
subtest 'check prolog 1', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <?xml version='1.0'?>
    <!DOCTYPE someElement>
    <someElement />
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  throws-like(
    { $a.process(:actions($w)); },
    X::XML::Actions::Stream, 'Second prolog forbidden',
    :message(/:s Second prolog forbidden/)
  );
}

#-------------------------------------------------------------------------------
subtest 'check element 1', {

  $file.IO.spurt(Q:q:to/EOXML/);
    <?xml version='1.0'?>
    <!DOCTYPE someElement>
    <someElement a=b></someElement>
    EOXML

  my XML::Actions::Stream $a .= new(:$file);

  my A $w .= new();
  throws-like(
    { $a.process(:actions($w)); },
    X::XML::Actions::Stream, 'attribute wrong',
    :message(/:s Parsing error/)
  );
}

#-------------------------------------------------------------------------------
done-testing;

unlink $file;
rmdir $dir;
