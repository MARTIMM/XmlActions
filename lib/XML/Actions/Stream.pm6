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
    [ <prolog>        || # start of xml
      <doctype>       || # doctype spec
      <pi>            || # processing instruction
      <comment>       || # comment elems
      <cdata>         || # data area
      <end-tag>       || # end of an element
      <element-tag>   || # start or start / end of an element
      $<text> = .*       # rest is between elems
    ]
  }

  token prolog {
    '<?' $<xml-name> = 'xml' \s+ <attr-list>? \s* '?>'
  }

  # a name can be used as an element name or an attribute name
  # [namespace ':']? name
  token xml-name {
    ( [<alnum> | '-' | '.' ]+ [ ':' [<alnum> | '-' | '.' ]+ ]? )
  }

  token attr-list { [ <attr> \s* ]* }

  token attr { <xml-name> \s* '=' \s* <string> }

  token string {
    [ <["]> $<text> = [<-["]>+] <["]> ||
      <[']> $<text> = [<-[']>+] <[']>
    ]
  }

  token pi {
    '<?' $<target> = [ [<alnum> | '-']+ ] \s+ $<program> = [ .*? ] '?>'
  }

  token comment { '<!--' $<text> = [ .*? ] '-->' }

  token cdata { '<[CDATA[' $<data> = [ .*? ] ']]>' }

  token doctype {
    '<!' DOCTYPE \s+ $<first-element> = <xml-name> \s+
    [ '[' $<dtd> = [<-[\]]>+] ']' ||
      [ SYSTEM \s+ $<dtd-location> = <string> ]?
    ]
    \s* '>'
  }

  token end-tag {
    '</' <xml-name> '>'
  }

  token element-tag {
    '<' <xml-name> [ \s+ <attr-list> ]? \s* $<start-end> = [ '/>' | '>' ]
  }
}

#-------------------------------------------------------------------------------
class XML::Actions::Stream:auth<github:MARTIMM> {

  has Str $!file;
  has XML::Actions::Stream::Work $!actions;
  has Array $!parent-path;

  has Bool $prolog-passed;    # only once at 1st line of doc
  has Bool $doc-type;         # only once at 1st or 2nd line of doc

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str:D :$!file! ) { }

  #-----------------------------------------------------------------------------
  multi method process ( XML::Actions::Stream::Work:D :$!actions! ) {

    # a DOCTYPE, comments, PI or CDATA can contain other '<' or '>' which are
    # not interpreted as normal element items. For these we must gather the
    # data until the end of the element.
    my Bool $in-cdata = False;    # look for ']]>' when True
    my Bool $in-comment = False;  # look for '-->'
    my Bool $in-pi = False;       # look for '?>'
    my Int $in-doctype = 0;       # look for '>' if 1
                                  # look for ']>' if 2
    my Bool $in-element = False;  # look for '>'
    my Bool $in-text = True;      # assume w're out of any type of element

    my @parent-list = ();
    my %attr-list = %();


    # read the xml text and deliver lines of
    # - start or end element
    # - special xml types like <?xml ...?>, <?pi...?>, <!--comment --> etc
    # - plain text
    my Str $buffer = '';
    my Proc $p = run 'cat', $!file, :out;
    my Seq $parseble-lines := lazy gather for $p.out.lines -> $line {
#note "Line: $line";

      my Int $index;
      my Bool $need-more = False;
      $buffer ~= "$line\n";

      # test if more text is needed. this happens when a specific character is
      # not found i.e. $index == undefined. If not, there is still something
      # left in the buffer to process.
      while !$need-more {
#note "Flgs0: $in-element, $in-cdata, $in-comment, $in-pi, $in-doctype";
#note "NM: $need-more, {$index//'-'}, $buffer";

        # <[CDATA[ ... ]]>
        if $in-cdata {
          $index = $buffer.index(']]>');
          if $index.defined {
            $in-cdata = False;
            take $buffer.substr( 0, $index + 3);
#note "Take E0: ", $buffer.substr( 0, $index + 3);
            $buffer .= substr($index + 3);
          }
        }

        # <!-- ... -->
        elsif $in-comment {
          $index = $buffer.index('-->');
          if $index.defined {
            $in-comment = False;
            take $buffer.substr( 0, $index + 3);
#note "Take E1: ", $buffer.substr( 0, $index + 3);
            $buffer .= substr($index + 3);
          }
        }

        # <?... ... ?> Also pick up the document prolog
        elsif $in-pi {
          $index = $buffer.index('?>');
          if $index.defined {
            $in-pi = False;
            take $buffer.substr( 0, $index + 2);
#note "Take E2: ", $buffer.substr( 0, $index + 2);
            $buffer .= substr($index + 2);
          }
        }

        # <!DOCTYPE ... >
        elsif $in-doctype == 1 {
          $index = $buffer.index('>');
          my $index-dtd = $buffer.index('[');
#note "DT: {$index//'-'}, {$index-dtd//'-'}";
          # when both defined check for relation, there could
          # be e.g CDATA further down the doc written on one line
          if $index-dtd.defined and $index.defined and
             $index-dtd < $index {
            $in-doctype = 2;
            next;
          }

          # promote to doctype == 2
          # <!DOCTYPE ... [ dtd ]>
          elsif $index-dtd.defined {
            $in-doctype = 2;
            next;
          }

          # else still doctype == 1
          elsif $index.defined {
            $in-doctype = 0;
            take $buffer.substr( 0, $index + 1);
#note "Take E3: ", $buffer.substr( 0, $index + 1);
            $buffer .= substr($index + 1);
          }
        }

        # <!DOCTYPE ... [ dtd ]>
        elsif $in-doctype == 2 {
          $index = $buffer.index(']>');
          if $index.defined {
            $in-doctype = 0;
            take $buffer.substr( 0, $index + 2);
#note "Take E4: ", $buffer.substr( 0, $index + 2);
            $buffer .= substr($index + 2);
          }
        }

        elsif $in-element {
          # search end of any kind of element also end tag
          $index = $buffer.index('>');
          if $index.defined {
            $in-element = False;
            take $buffer.substr( 0, $index + 1);
            $buffer .= substr($index + 1);
#note "Take E5: ", $index//'-', ', ', $buffer.substr( 0, $index + 1);
          }
        }

        elsif $in-text {
          # search start of any kind of element also end tag.
          $index = $buffer.index('<');

          # if undefined, we need more. if 0, no text.
          if ?$index {
            $in-text = False;
            take $buffer.substr( 0, $index);
#note "Take E6: ", $index//'-', ', ', $buffer.substr( 0, $index);
            $buffer .= substr($index);
          }

          elsif $index.defined and $index == 0 {
            # turn off text processing, next round it checks what it is
            $in-text = False;
          }
        }

        else {
          if ($index = $buffer.index('<!DOCTYPE')).defined and $index == 0 {
            $in-doctype = 1;
          }

          elsif ($index = $buffer.index('<?')).defined and $index == 0 {
            $in-pi = True;
          }

          elsif ($index = $buffer.index('<!--')).defined and $index == 0 {
            $in-comment = True;
          }

          elsif ($index = $buffer.index('<[CDATA[')).defined and $index == 0 {
            $in-cdata = True;
          }

          elsif ($index = $buffer.index('<')).defined and $index == 0 {
            $in-element = True;
          }

          else {
            $in-text = True;
          }

#note "Flgs1: $in-element, $in-cdata, $in-comment, $in-pi, $in-doctype";
#`{{
          $index = $buffer.index('>');
          if $index.defined {
            $in-element = False;
            take $buffer.substr( 0, $index + 1);
#note "Take E2: ", $buffer.substr( 0, $index + 1);
            $buffer .= substr($index + 1);
          }
}}
        }

        $need-more = True unless $index.defined;
#exit 0 if $++ > 10;
      }
    }

    self.parse-parts($parseble-lines);
  }

  #-----------------------------------------------------------------------------
  method parse-parts ( Seq $parseble-lines ) {

    $!parent-path = [];
    $prolog-passed = $doc-type = False;


    # parseble lines
    for @$parseble-lines -> $line {
#note "L: $line" unless $line ~~ /^ \s* $/;

      my $match = XmlNode.parse( $line, :rule<Xml>);
#note "M: ", ~$match;
      if $match<prolog> {
        die X::XML::Actions::Stream.new(:message("Second prolog forbidden"))
            if $prolog-passed;

#        note "prolog: ", ~$match<prolog><xml-name>;
#        note "attrs: ", self.get-attributes($match<prolog><attr-list>);

        if $!actions.^can('xml:prolog') {
          $!actions."xml:prolog"(
            |(self.get-attributes($match<prolog><attr-list>))
          );
        }

        $prolog-passed = True;
      }

      elsif $match<doctype> {
        die X::XML::Actions::Stream.new(:message("Second doctype forbidden"))
            if $doc-type;

#note "start: ", ~$match<doctype><first-element>;
        if ?$match<doctype><dtd> {
#          note "DTD: ", ~$match<doctype><dtd>;

          if $!actions.^can('xml:doctype') {
            $!actions."xml:doctype"(:dtd-text(~$match<doctype><dtd>));
          }
        }

        elsif ?$match<doctype><dtd-location> {
#          note "DTD: ", ~$match<doctype><dtd-location><text>;

          if $!actions.^can('xml:doctype') {
            $!actions."xml:doctype"(:dtd-url(~$match<doctype><dtd-location>));
          }
        }

        else {
#          note "-";

          if $!actions.^can('xml:doctype') {
            $!actions."xml:doctype"(:empty);
          }
        }

        $doc-type = True;
      }

      elsif $match<element-tag> {
        my Str $name = ~$match<element-tag><xml-name>;
        my %attribs = self.get-attributes($match<element-tag><attr-list>);
        $!parent-path.push: $name => %attribs;

        my Str $mname;
        if $!actions.^can($mname = $name ~ ':start') {
          $!actions."$mname"( $!parent-path, |%attribs);
        }

        if ~$match<element-tag><start-end> eq '/>' and
          $!actions.^can($mname = $name ~ ':startend') {
          $!actions."$mname"( $!parent-path, |%attribs);
          $!parent-path.pop;
        }


#        note "start: ", ~$match<element-tag><xml-name>;
#        note "attrs: ", self.get-attributes($match<element-tag><attr-list>);
      }

      elsif $match<end-tag> {
#        note "end: ", ~$match<end-tag><xml-name>;

        my Str $mname;
        if $!actions.^can($mname = $match<end-tag><xml-name> ~ ':end') {
          $!actions."$mname"(
            $!parent-path, |$!parent-path[*-1]{~$match<end-tag><xml-name>}
          );
        }

        $!parent-path.pop;
      }

      elsif $match<pi> {
#        note "pi: ", ~$match<pi><target>, "\n", ~$match<pi><program>;

        if $!actions.^can('xml:pi') {
          $!actions."xml:pi"(
            $!parent-path, ~$match<pi><target>, ~$match<pi><program>
          );
        }
    }

      elsif $match<comment> {
#        note "comment: ", ~$match<comment><text>;

        if $!actions.^can('xml:comment') {
          $!actions."xml:comment"( $!parent-path, ~$match<comment><text>);
        }
      }

      elsif $match<cdata> {
#        note "cdata: ", ~$match<cdata><data>;

        if $!actions.^can('xml:cdata') {
          $!actions."xml:cdata"( $!parent-path, ~$match<cdata><data>);
        }
      }

      else {
#        note "Text: ", ~$match<text>;

        if $!actions.^can('xml:text') {
          $!actions."xml:text"( $!parent-path, ~$match<text>);
        }
      }


#note "  A: ", $match<attr-list><attr>;

#      for @($match<attr-list>.caps) -> $attr {
#note "  A: ", ~$attr<xml-name>[0], ' => ', ~$attr<attr-value>[0];
#      }

    }
  }

  #-----------------------------------------------------------------------------
  method get-attributes ( $m --> Hash ) {

    my %a = %();
    return %a unless ?$m;

    for @($m.caps) -> $attr-spec {
#note "  A: ", ~$attr-spec<attr><xml-name>,
#              ' => ', ~$attr-spec<attr><string><text>;
      %a{~$attr-spec<attr><xml-name>} = ~$attr-spec<attr><string><text>;
    }

    %a
  }
}
