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
class XML::Actions::Stream:auth<github:MARTIMM> {
  use XML::Actions::Stream::XmlNode;

  has Str $!file;
  has XML::Actions::Stream::Work $!actions;
  has Array $!parent-path;
  has Str $!root-element;

  has Bool $!prolog-passed;   # only once at 1st line of doc
  has Bool $!doctype-passed;  # only once at 1st or 2nd line of doc
  has Bool $!elements-seen = False;

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

    my Channel $parsable-lines-channel .= new;
    my Promise $read-file .= start( {
#        my Proc $p = run 'cat', $!file, :out;
        my $handle = $!file.IO.open(:mode<ro>);
        while my Str $char-block = $handle.readchars {

          my Int $index;
          my Bool $need-more = False;
          $buffer ~= "$char-block";

          # test if more text is needed. this happens when a specific
          # character is not found i.e. $index == undefined. If not, there
          # is still something left in the buffer to process.
          while !$need-more {
      #note "Flgs0: $in-element, $in-cdata, $in-comment, $in-pi, $in-doctype";
      #note "NM: $need-more, {$index//'-'}, $buffer";

            # <[CDATA[ ... ]]>
            if $in-cdata {
              $index = $buffer.index(']]>');
              if $index.defined {
                $in-cdata = False;
      #            take $buffer.substr( 0, $index + 3);
                $parsable-lines-channel.send($buffer.substr( 0, $index + 3));
      #note "Take E0: ", $buffer.substr( 0, $index + 3);
                $buffer .= substr($index + 3);
              }
            }

            # <!-- ... -->
            elsif $in-comment {
              $index = $buffer.index('-->');
              if $index.defined {
                $in-comment = False;
      #            take $buffer.substr( 0, $index + 3);
                $parsable-lines-channel.send($buffer.substr( 0, $index + 3));
      #note "Take E1: ", $buffer.substr( 0, $index + 3);
                $buffer .= substr($index + 3);
              }
            }

            # <?... ... ?> Also pick up the document prolog
            elsif $in-pi {
              $index = $buffer.index('?>');
              if $index.defined {
                $in-pi = False;
      #            take $buffer.substr( 0, $index + 2);
                $parsable-lines-channel.send($buffer.substr( 0, $index + 2));
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
      #            take $buffer.substr( 0, $index + 1);
                $parsable-lines-channel.send($buffer.substr( 0, $index + 1));
      #note "Take E3: ", $buffer.substr( 0, $index + 1);
                $buffer .= substr($index + 1);
              }
            }

            # <!DOCTYPE ... [ dtd ]>
            elsif $in-doctype == 2 {
              $index = $buffer.index(']>');
              if $index.defined {
                $in-doctype = 0;
      #            take $buffer.substr( 0, $index + 2);
                $parsable-lines-channel.send($buffer.substr( 0, $index + 2));
      #note "Take E4: ", $buffer.substr( 0, $index + 2);
                $buffer .= substr($index + 2);
              }
            }

            elsif $in-element {
              # search end of any kind of element also end tag
              $index = $buffer.index('>');
              if $index.defined {
                $in-element = False;
      #            take $buffer.substr( 0, $index + 1);
                $parsable-lines-channel.send($buffer.substr( 0, $index + 1));
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
      #            take $buffer.substr( 0, $index);
                $parsable-lines-channel.send($buffer.substr( 0, $index));
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

      #note "Size: $need-more, $buffer.chars()";
          }
        }

        # rest of the buffer should be empty. if not, it should fail
        # in the matching process and not end here
        $parsable-lines-channel.send($buffer) if $buffer.chars;

        # send a finishing touch. this line is illegal xml so it cannot happen
        $parsable-lines-channel.send('<<__:FINISHED:__>>');
#        $p.out.close;
#        $handle.close;
#        $parsable-lines-channel.close;
      }

    );

    self.parse-parts($parsable-lines-channel);

  }

  #-----------------------------------------------------------------------------
#  method parse-parts ( Seq $parsable-lines ) {
  method parse-parts ( Channel $parsable-lines-channel ) {

    $!parent-path = [];
    $!prolog-passed = $!doctype-passed = False;
    while $parsable-lines-channel.receive -> $line {
#note "L: $line";
      last if $line eq '<<__:FINISHED:__>>';

      my $match = XML::Actions::Stream::XmlNode.parse( $line, :rule<Xml>);
      if !$match.defined {
#        $match = XML::Actions::Stream::XmlNode.subparse( $line, :rule<Xml>);
#note "Me1: ", ~$match;
#note "Me2: ", $match.perl;
        die X::XML::Actions::Stream.new(:message("Parsing error: '$line'"));
      }
#note "M1: ", ~$match;
#note "M2: ", $match;

      if $match<prolog> {
        die X::XML::Actions::Stream.new(
          :message("Second prolog forbidden or at wrong place")
        ) if $!prolog-passed;

#note "prolog: ", ~$match<prolog><xml-name>;
#note "attrs: ", self.get-attributes($match<prolog><attr-list>);

        if $!actions.^can('xml:prolog') {
          $!actions."xml:prolog"(
            |(self.get-attributes($match<prolog><attr-list>))
          );
        }

        $!prolog-passed = True;
      }

      elsif $match<doctype> {
        die X::XML::Actions::Stream.new(:message("Doctype at wrong place"))
          if $!elements-seen and !$!doctype-passed;

        die X::XML::Actions::Stream.new(:message("Second doctype forbidden"))
          if $!doctype-passed;

        $!root-element = ~$match<doctype><root-element>;
        my %attributes = %( :!empty, :$!root-element);

        my Match $chk;
        if ?($chk = $match<doctype><system-dtd>) {
          %attributes<system> = True;
          %attributes<dtd> = ~$chk<dtd> if ?$chk<dtd>;
          %attributes<url> = ~$chk<url><text> if ?$chk<url>;
        }

        elsif ?($chk = $match<doctype><public-dtd>) {
          %attributes<public> = True;
          %attributes<fpi> = ~$chk<fpi><text> if ?$chk<fpi>;
          %attributes<dtd> = ~$chk<dtd> if ?$chk<dtd>;
          %attributes<url> = ~$chk<url><text> if ?$chk<url>;
        }

        elsif ?($chk = $match<doctype><dtd>) {
          %attributes<dtd> = ~$chk;
        }

        else {
          %attributes<empty> = True;
        }

#note "Attrs: ", %attributes;

        if $!actions.^can('xml:doctype') {
          $!actions."xml:doctype"(|%attributes);
        }

        $!doctype-passed = True;
      }

      elsif $match<element-tag> {
        my Str $name = ~$match<element-tag><xml-name>;
        die X::XML::Actions::Stream.new(
          :message("root element $name is not $!root-element from DTD")
        ) if $!parent-path.elems == 0 and
             ?$!root-element and $!root-element ne $name;

        $!elements-seen = True;

        my %attribs = self.get-attributes($match<element-tag><attr-list>);
        $!parent-path.push: $name => %attribs;

        my Str $mname;
        if ~$match<element-tag><start-end> eq '/>' {
          # show that next statement has no content
          if $!actions.^can($mname = $name ~ ':startend') {
            $!actions."$mname"( $!parent-path, |%attribs);
          }
        }

        if $!actions.^can($mname = $name ~ ':start') {
          $!actions."$mname"( $!parent-path, |%attribs);
        }

        $!parent-path.pop if ~$match<element-tag><start-end> eq '/>';


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
        die X::XML::Actions::Stream.new(
          :message("Processing instructions only in elements")
        ) if !$!elements-seen;

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
        die X::XML::Actions::Stream.new(
          :message("cdata only in elements")
        ) if !$!elements-seen;

        if $!actions.^can('xml:cdata') {
          $!actions."xml:cdata"( $!parent-path, ~$match<cdata><data>);
        }
      }

      elsif $match<text> {
#        note "Text: ", ~$match<text>;

        if $!actions.^can('xml:text') {
          $!actions."xml:text"( $!parent-path, ~$match<text>);
        }
      }

      else {
note "No match";
      }

      # If anything is processed a prolog cannot happen anymore
      $!prolog-passed = True;

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
