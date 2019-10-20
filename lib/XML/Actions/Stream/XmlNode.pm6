use v6;

#use Grammar::Tracer;
#no precompilation;

#-------------------------------------------------------------------------------
unit grammar XML::Actions::Stream::XmlNode:auth<github:MARTIMM>;

token Xml {
  [ '<' <next-part-of-tag> ] |
  <text>
}

token next-part-of-tag {
  [ '!' <type1-elements> ] |
  [ '?' <type2-elements> ] |
  [ '[' <type3-elements> ] |
  [ '/' <end-element>    ] |
  <element>
}

token type1-elements {
  [ DOCTYPE <doctype> ] |
  '--' <comment>
}

rule type2-elements {
  [ xml <prolog> ] |
  <pi>
}

token type3-elements { 'CDATA[' <cdata> }

token doctype {
  \s+ $<root-element> = <xml-name>
  [ \s+ [ <system-dtd> | <public-dtd> | <dtd> ]]?
  \s* '>'
}

token comment { $<text> = [ .*? ] '-->' }

rule prolog { <attr-list>? '?>'}

token pi { $<target> = [ [<alnum> | '-']+ ] \s+ $<program> = [ .*? ] '?>'}

token cdata { $<data> = [ .*? ] ']]>' }

token end-element { <xml-name> '>' }

token element {
  <xml-name> [ \s+ <attr-list> ]? \s* $<start-end> = [ '/>' | '>' ]
}

# a name can be used as an element name or an attribute name
# [namespace ':']? name
token xml-name { <[\w\-\.]>+ [ ':' <[\w\-\.]>+ ]? }

rule attr-list { [ <attr> ]* }

rule attr { <xml-name> '=' <string> }

token string {
  [ <["]> $<text> = [<-["]>+] <["]> ||
    <[']> $<text> = [<-[']>+] <[']>
  ]
}

token text { <-[<>]>* }

token dtd {
  '[' $<dtd-text> = [<-[\]]>+] ']'
}

token system-dtd {
  SYSTEM \s+ $<url> = <string> [ \s+ <dtd> ]?
}

token public-dtd {
  PUBLIC \s+ $<fpi> = <string> [ \s* $<url> = <string> ]? [ \s+ <dtd> ]?
}









=finish
#-------------------------------------------------------------------------------
unit grammar XML::Actions::Stream::XmlNode:auth<github:MARTIMM>;

token Xml {
  [ <prolog>        || # start of xml
    <doctype>       || # doctype spec
    <pi>            || # processing instruction
    <comment>       || # comment elems
    <cdata>         || # data area
    <end-tag>       || # end of an element
    <element-tag>   || # start or start / end of an element
    <text>             # rest is between elems
  ]
}

token prolog {
  '<?' $<xml-name> = 'xml' \s+ <attr-list>? \s* '?>'
}

token doctype {
  '<!' DOCTYPE \s+ $<root-element> = <xml-name>
  [ \s+ [ <system-dtd> || <public-dtd> || <dtd> ]]?
  \s* '>'
}

token pi {
  '<?' $<target> = [ [<alnum> | '-']+ ] \s+ $<program> = [ .*? ] '?>'
}

token comment { '<!--' $<text> = [ .*? ] '-->' }

token cdata { '<[CDATA[' $<data> = [ .*? ] ']]>' }

token end-tag { '</' <xml-name> '>' }

token element-tag {
  '<' <xml-name> [ \s+ <attr-list> ]? \s* $<start-end> = [ '/>' | '>' ]
}

token text {
   <-[&<>]>*
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

token dtd {
  '[' $<dtd-text> = [<-[\]]>+] ']'
}

token system-dtd {
  SYSTEM \s+ $<url> = <string> [ \s+ <dtd> ]?
}

token public-dtd {
  PUBLIC \s+ $<fpi> = <string> [ \s* $<url> = <string> ]? [ \s+ <dtd> ]?
}
