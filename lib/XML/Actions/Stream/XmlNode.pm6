use v6;

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
  '<!' DOCTYPE \s+ $<root-element> = <xml-name>
  [ \s+ [ <system-dtd> || <public-dtd> || <dtd> ]]?
  \s* '>'
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

token end-tag { '</' <xml-name> '>' }

token element-tag {
  '<' <xml-name> [ \s+ <attr-list> ]? \s* $<start-end> = [ '/>' | '>' ]
}

token text {
   <-[&<>]>*
}
