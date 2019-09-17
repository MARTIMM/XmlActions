use v6;

#-------------------------------------------------------------------------------
class X::XML::Actions::Stream:auth<github:MARTIMM> is Exception {
  has Str $.message;            # Error text and error code are data mostly
#  has Str $.method;             # Method or routine name
#  has Int $.line;               # Line number where Message is called
#  has Str $.file;               # File in which that happened
}

#-------------------------------------------------------------------------------
class XML::Actions::Stream::Work:auth<github:MARTIMM> { }

#-------------------------------------------------------------------------------
my grammar XmlNode {
  token Xml {
    [ \s* '<?' $<name>='xml' \s+ <attr-list> \s* '?>' ||
      \s* '<' <name> \s+ <attr-list> \s* ['>' || '/>'] ||
      \s* '</' <name> '>'
    ]
  }

  token name {
    ( [<alnum> | '-' ]+ [ ':' [<alnum> | '-' ]+ ]? )
  }

  token attr-list { [ <attr> \s* ]* }

  token attr { <attr-name> '=' <["']> $<attr-value>=[<-['"]>+] <['"]> }

  token attr-name {
    ( [<alnum> | '-' ]+ [ ':' [<alnum> | '-' ]+ ]? )
  }
}

#-------------------------------------------------------------------------------
class XML::Actions::Stream:auth<github:MARTIMM> {

  has Str $!file;
  has XML::Actions::Stream::Work $!actions;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str:D :$!file! ) { }

  #-----------------------------------------------------------------------------
  multi method process ( XML::Actions::Stream::Work:D :$!actions! ) {

    my Bool $in-element = False;
    my @parent-list = ();
    my %attr-list = %();


    # read the xml text and deliver lines of
    # - start or end element
    # - special xml types like <?xml ...?>, <?pi...?>, <!--comment --> etc
    # - plain text
    my Str $buffer = '';
    my Proc $p = run 'cat', $!file, :out;
    my Seq $parseble-lines := lazy gather for $p.out.lines -> $line {
note "L: $line";

      my Int $index;
      $buffer ~= "$line\n";

      if $in-element {
        # search end of any kind of element also end tag
        $index = $buffer.index('>');
        $in-element = False if $index.defined;
      }

      else {
        # search start of any kind of element also end tag
        $index = $buffer.index('<');
        $in-element = True if $index.defined;
      }

      if $index.defined {
        take $buffer.substr( 0, $index);
        $buffer .= substr($index + 1);
      }
    }


    # parseble lines
    for @$parseble-lines -> $line {
note "PL: $line";
#`{{
      my $match = XmlNode.parse( $line, :rule<Xml>);
note "M: ", ~$match;
      note "E: ", ~$match<name>;#, "\n", $match.perl;
note "  A: ", $match<attr-list><attr>;

      for @($match<attr-list>.caps) -> $attr {
note "  A: ", ~$attr<attr-name>[0], ' => ', ~$attr<attr-value>[0];
      }
}}
    }
  }
}
