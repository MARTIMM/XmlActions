use v6;

use XML;

#-------------------------------------------------------------------------------
class X::XML::Actions:auth<github:MARTIMM> is Exception {
  has Str $.message;            # Error text and error code are data mostly
#  has Str $.method;             # Method or routine name
#  has Int $.line;               # Line number where Message is called
#  has Str $.file;               # File in which that happened
}

#-------------------------------------------------------------------------------
class XML::Actions::Work:auth<github:MARTIMM> {
}

#-------------------------------------------------------------------------------
class XML::Actions:auth<github:MARTIMM> {

  has XML::Document $!document;
  has $!actions;
  has Array $!parent-path;

  #-----------------------------------------------------------------------------
  multi submethod BUILD ( Str:D :$file! ) {
    die X::XML::Actions.new(:message("File '$file' not found")) unless $file.IO ~~ :r;
    $!document = from-xml-file($file);
  }

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
    XML::Document:D :$!document!,XML::Actions::Work:D :$!actions!
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
        self!check-action($node);
        for $node.nodes -> $child { self!process-node($child); }
        $!parent-path.pop;
      }

      when XML::Text {
        if $!actions.^can('PROCESS-TEXT') {
          $!actions.PROCESS-TEXT( $!parent-path, $node.text());
        }
      }

      when XML::Comment {
        if $!actions.^can('PROCESS-COMMENT') {
          $!actions.PROCESS-COMMENT( $!parent-path, $node.data());
        }
      }

      when XML::CDATA {
        if $!actions.^can('PROCESS-CDATA') {
          $!actions.PROCESS-CDATA( $!parent-path, $node.data());
        }
      }

      when XML::PI {
        if $!actions.^can('PROCESS-PI') {
          my Str $target;
          my Str $content;
          ( $target, $content) = $node.data().split( ' ', 2);
          $!actions.PROCESS-PI( $!parent-path, $target, $content);
        }
      }
    }
  }

  #-----------------------------------------------------------------------------
  method !check-action ( $node ) {

    my Str $name = $node.name;
    my %attribs = $node.attribs;

    if $!actions.^can($name) {
      $!actions."$name"( $!parent-path, |%attribs);
    }
  }
}
