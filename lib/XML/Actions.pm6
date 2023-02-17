use v6;

use XML;
#use HTML::Parser::XML;

#-------------------------------------------------------------------------------
class X::XML::Actions:auth<github:MARTIMM> is Exception {
  has Str $.message;            # Error text and error code are data mostly
#  has Str $.method;             # Method or routine name
#  has Int $.line;               # Line number where Message is called
#  has Str $.file;               # File in which that happened
}

#-------------------------------------------------------------------------------
class XML::Actions::Work:auth<github:MARTIMM> { }

#-------------------------------------------------------------------------------
class XML::Actions:auth<github:MARTIMM> {

  # possible action results on XML:Element action methods
  enum ActionResult is export <Recurse Truncate>;

  # temp gather element names to see if already a message is printed
#  state %element-errors = %();

  has XML::Document $!document;
  has $!actions;
  has Array $!parent-path;

  #-----------------------------------------------------------------------------
  multi submethod BUILD (Str :$file!) {
    die X::XML::Actions.new(:message("File '$file' not found"))
        unless $file.IO ~~ :r;

    $!document = from-xml-file($file);
  }

  #-----------------------------------------------------------------------------
  multi submethod BUILD (Str :$xml!) {
    die X::XML::Actions.new( :message('XML is empty!') )
      unless $xml.trim.chars;
    $!document = from-xml($xml);
  }

#`{{
  #-----------------------------------------------------------------------------
  multi submethod BUILD (Str :$html!) {
    die X::XML::Actions.new( :message('XML is empty!') )
      unless $html.trim.chars;
    my $parser = HTML::Parser::XML.new;
    $!document = $parser.parse($html);
  }
}}

  #-----------------------------------------------------------------------------
  multi submethod BUILD ( XML::Document:D :$!document! ) { }

  #-----------------------------------------------------------------------------
  multi submethod BUILD ( ) { $!document = XML::Document; }


  #-----------------------------------------------------------------------------
  multi method process ( Str:D :$file!, XML::Actions::Work:D :$!actions! ) {

    die X::XML::Actions.new(:message("File not found")) unless $file.IO ~~ :r;
    $!document = from-xml-file($file);

    self!process-document;
  }

  #-----------------------------------------------------------------------------
  multi method process (
    XML::Document:D :$!document!, XML::Actions::Work:D :$!actions!
  ) {
    self!process-document;
  }

  #-----------------------------------------------------------------------------
  multi method process ( XML::Actions::Work:D :$!actions! ) {

    die X::XML::Actions.new(:message("No xml document to work on"))
      unless $!document.defined;

    self!process-document;
  }

  #-----------------------------------------------------------------------------
  # Things can be changed while processing
  method result ( --> Str ) {
    $!document.Str
  }

  #-----------------------------------------------------------------------------
  method !process-document ( ) {
    my XML::Element $root = $!document.root();

    $!parent-path = [];
    self!process-node($root);
  }

  #-----------------------------------------------------------------------------
  method !process-node ( $node ) {

    given $node {
      when XML::Element {
        $!parent-path.push($node);
        with self!check-action($node) {
          when Recurse {
            for $node.nodes -> $child { self!process-node($child); }
          }

          when Truncate {
            note "$node.name() truncated";
          }
        }
        self!check-end-node-action($node);
        $!parent-path.pop;
      }

      when XML::Text {
        if $!actions.^can('xml:text') {
          $!actions.'xml:text'( $!parent-path, $node.text());
        }
      }

      when XML::Comment {
        if $!actions.^can('xml:comment') {
          $!actions.'xml:comment'( $!parent-path, $node.data());
        }
      }

      when XML::CDATA {
        if $!actions.^can('xml:cdata') {
          $!actions.'xml:cdata'( $!parent-path, $node.data());
        }
      }

      when XML::PI {
        if $!actions.^can('xml:pi') {
          my Str $target;
          my Str $content;
          ( $target, $content) = $node.data().split( ' ', 2);
          $!actions.'xml:pi'( $!parent-path, $target, $content);
        }
      }
    }
  }

  #-----------------------------------------------------------------------------
  method !check-action ( $node --> ActionResult ) {

    my Str $name = $node.name;
    my %attribs = $node.attribs;
    my ActionResult $state = Recurse;

    my Str $start-node = $name ~ ":start";
    if $!actions.^can($start-node) {
      my $t = $!actions."$start-node"( $!parent-path, |%attribs);

      # Check type and definedness. Only defined Boolean values are taken.
      # All other possibilities are False by default.
      $state = $t ~~ ActionResult ?? $t//Recurse !! Recurse;
    }

    $state;
  }

  #-----------------------------------------------------------------------------
  method !check-end-node-action ( $node ) {

    my Str $name = $node.name;
    my %attribs = $node.attribs;

    my Str $end-node = $name ~ ":end";
    if $!actions.^can($end-node) {
      $!actions."$end-node"( $!parent-path, |%attribs);
    }
  }
}
