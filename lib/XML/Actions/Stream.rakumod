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

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str:D :$!file! ) { }

  #-----------------------------------------------------------------------------
  multi method process ( XML::Actions::Stream::Work:D :$!actions! ) {

    # a DOCTYPE can have a DTDF inside with element like entries. For this
    # we must gather the data until the end of the element.
    my Int $in-doctype = 0;       # look for '>' if 1
                                  # look for ']>' if 2, it has DTD
    my Bool $in-element = False;  # look for '>'
    my Bool $in-text = True;      # assume w're out of any type of element

    my @parent-list = ();
    my %attr-list = %();


    # read the xml text and deliver lines of
    # - special xml type <!DOCTYPE ...> can have a DTD and element like entries
    # - start or end element with special type elements
    # - plain text
    my Str $buffer = '';

    my Channel $parseble-lines-channel .= new;
    my Promise $read-file .= start( {
        my $handle = $!file.IO.open(:mode<ro>);
        while my Str $char-block = $handle.readchars(131072) {

          my Int $index;
          my Bool $need-more = False;
          $buffer ~= "$char-block";

          # test if more text is needed. this happens when a specific
          # character is not found i.e. $index == undefined. If not, there
          # is still something left in the buffer to process.
          while !$need-more {

            # <!DOCTYPE ... >
            if $in-doctype == 1 {
              $index = $buffer.index('>');
              my $index-dtd = $buffer.index('[');

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
                $parseble-lines-channel.send($buffer.substr( 0, $index + 1));
                $buffer .= substr($index + 1);
              }
            }

            # <!DOCTYPE ... [ dtd ]>
            elsif $in-doctype == 2 {
              $index = $buffer.index(']>');
              if $index.defined {
                $in-doctype = 0;
                $parseble-lines-channel.send($buffer.substr( 0, $index + 2));
                $buffer .= substr($index + 2);
              }
            }

            elsif $in-element {
              # search end of any kind of element also end tag
              $index = $buffer.index('>');
              if $index.defined {
                $in-element = False;
                $parseble-lines-channel.send($buffer.substr( 0, $index + 1));
                $buffer .= substr($index + 1);
              }
            }

            elsif $in-text {
              # search start of any kind of element also end tag.
              $index = $buffer.index('<');

              # if undefined, we need more. if 0, no text.
              if ?$index {
                $in-text = False;
                $parseble-lines-channel.send($buffer.substr( 0, $index));
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

              elsif ($index = $buffer.index('<')).defined and $index == 0 {
                $in-element = True;
              }

              else {
                $in-text = True;
              }
            }

            $need-more = True unless $index.defined;
          }
        }

        # rest of the buffer should be empty. if not, it should fail
        # in the matching process and not end here
        $parseble-lines-channel.send($buffer) if $buffer.chars;

        # send a finishing touch. this line is illegal xml so it cannot happen
        $parseble-lines-channel.send('<<__:FINISHED:__>>');

      } # End block
    );  # end Promise

    self.parse-parts($parseble-lines-channel);
  }

  #-----------------------------------------------------------------------------
  method parse-parts ( Channel $parseble-lines-channel ) {

    $!parent-path = [];
    while $parseble-lines-channel.receive -> $line {
#note "L: $line";
      last if $line eq '<<__:FINISHED:__>>';

      my $match = XML::Actions::Stream::XmlNode.parse( $line, :rule<Xml>);
      die X::XML::Actions::Stream.new(:message("Parsing error: '$line'"))
        unless $match.defined;

      my $m;

      if $match<next-part-of-tag>:exists {
        given $match<next-part-of-tag> {
          when $_<type1-elements><doctype>:exists {
            if $!actions.^can('xml:doctype') {
              $m = $_<type1-elements><doctype>;

              # empty is meant to show if there is a dtd, system-dtd or
              # public-dtd (False) or otherwise empty (True)
              my %attributes = %(
                :!empty,
                :root-element(~$m<root-element>)
              );

              my Match $chk;
              if ?($chk = $m<system-dtd>) {
                %attributes<system> = True;
                %attributes<dtd> = ~$chk<dtd> if ?$chk<dtd>;
                %attributes<url> = ~$chk<url><text> if ?$chk<url>;
              }

              elsif ?($chk = $m<public-dtd>) {
                %attributes<public> = True;
                %attributes<fpi> = ~$chk<fpi><text> if ?$chk<fpi>;
                %attributes<dtd> = ~$chk<dtd> if ?$chk<dtd>;
                %attributes<url> = ~$chk<url><text> if ?$chk<url>;
              }

              elsif ?($chk = $m<dtd>) {
                %attributes<dtd> = ~$chk;
              }

              else {
                %attributes<empty> = True;
              }

#note "Attrs: ", %attributes;

              $!actions."xml:doctype"(|%attributes);
            }
          }

          when $_<type1-elements><comment>:exists {
            $!actions.?"xml:comment"(
              $!parent-path, ~$_<type1-elements><comment><text>
            );
          }

          # <?xml version='...' standalone='...' ?>
          when $_<type2-elements><prolog>:exists {
            if $!actions.^can('xml:prolog') {
              $!actions."xml:prolog"(
                |(self.get-attributes($_<type2-elements><prolog><attr-list>))
              );
            }
          }

          when $_<type2-elements><pi>:exists {
            $!actions.?"xml:pi"(
              $!parent-path,
              ~$_<type2-elements><pi><target>,
              ~$_<type2-elements><pi><program>
            );
          }

          when $_<type3-elements><cdata>:exists {
            $!actions.?"xml:cdata"(
              $!parent-path, ~$_<type3-elements><cdata><data>
            );
          }

          when $_<end-element>:exists {
            $m = $_<end-element>;
            if $!actions.^can(my $mname = ~$m<xml-name> ~ ':end') {
              $!actions."$mname"(
                $!parent-path, |$!parent-path[*-1]{~$m<xml-name>}
              );
            }

            $!parent-path.pop;
          }

          when $_<element>:exists {
            $m = $_<element>;
            my Str $name = ~$m<xml-name>;
            my %attribs = self.get-attributes($m<attr-list>);
            $!parent-path.push: $name => %attribs;

            if $!actions.^can(my $mname = $name ~ ':start') {
              my Bool $startend = ~$m<start-end> eq '/>';
              $!actions."$mname"( $!parent-path, :$startend, |%attribs);
            }

            $!parent-path.pop if ~$m<start-end> eq '/>';
          }
        }
      }

      elsif $match<text>:exists {
        $!actions.?"xml:text"( $!parent-path, ~$match<text>);
      }

#`{{
      if $match<prolog> {

#note "prolog: ", ~$match<prolog><xml-name>;
#note "attrs: ", self.get-attributes($match<prolog><attr-list>);

        if $!actions.^can('xml:prolog') {
          $!actions."xml:prolog"(
            |(self.get-attributes($match<prolog><attr-list>))
          );
        }
      }

      elsif $match<doctype> {
        my %attributes = %(
          :!empty,
          :root-element(~$match<doctype><root-element>)
        );

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
      }

      elsif $match<element-tag> {
        my Str $name = ~$match<element-tag><xml-name>;
        my %attribs = self.get-attributes($match<element-tag><attr-list>);
        $!parent-path.push: $name => %attribs;

        my Str $mname;
        my Bool $startend = ~$match<element-tag><start-end> eq '/>';
#`{{
        if $startend {
          # show that next statement has no content
          if $!actions.^can($mname = $name ~ ':startend') {
            $!actions."$mname"( $!parent-path, |%attribs);
          }
        }
}}
        if $!actions.^can($mname = $name ~ ':start') {
          $!actions."$mname"( $!parent-path, :$startend, |%attribs);
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
        if $!actions.^can('xml:pi') {
          $!actions."xml:pi"(
            $!parent-path, ~$match<pi><target>, ~$match<pi><program>
          );
        }
      }

      elsif $match<comment> {
        if $!actions.^can('xml:comment') {
          $!actions."xml:comment"( $!parent-path, ~$match<comment><text>);
        }
      }

      elsif $match<cdata> {
        if $!actions.^can('xml:cdata') {
          $!actions."xml:cdata"( $!parent-path, ~$match<cdata><data>);
        }
      }

      elsif $match<text> {
        if $!actions.^can('xml:text') {
          $!actions."xml:text"( $!parent-path, ~$match<text>);
        }
      }
}}
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
