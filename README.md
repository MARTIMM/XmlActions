# XML Actions on every node
<!--
# ![Leaf](logotype/logo_32x32.png) MongoDB Driver
[![Build Status](https://travis-ci.org/MARTIMM/mongo-perl6-driver.svg?branch=master)](https://travis-ci.org/MARTIMM/mongo-perl6-driver) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/jhp0p39sydufxmw7?svg=true&branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20FAIL&pendingText=Windows%20-%20pending)](https://ci.appveyor.com/project/MARTIMM/mongo-perl6-driver/branch/master) [![License](http://martimm.github.io/label/License-label.svg)](http://www.perlfoundation.org/artistic_license_2_0)
-->

## Synopsis
```
use Test;
use XML::Actions;

my Str $file = "a.xml";
$file.IO.spurt(Q:q:to/EOXML/);
  <scxml xmlns="http://www.w3.org/2005/07/scxml"
         version="1.0"
         initial="hello">

    <final id="hello">
      <onentry>
        <log expr="'hello world'" />
      </onentry>
    </final>
  </scxml>
  EOXML


class A is XML::Actions::Work {
  method final ( Array $parent-path, :$id ) {
    is $id, 'hello', "final called: id = $id";
    is $parent-path[*-1].name, 'final', 'this node is final';
    is $parent-path[*-2].name, 'scxml', 'parent node is scxml';
  }

  method log ( Array $parent-path, :$expr ) {
    is $expr, "'hello world'", "log called: expr = $expr";
    is $parent-path[*-1].name, 'log', 'this node is log';
    is $parent-path[*-2].name, 'onentry', 'parent node is onentry';
  }
}

my XML::Actions $a .= new(:$file);
isa-ok $a, XML::Actions, 'type ok';
$a.process(:actions(A.new()));

```
Result would be like
```
ok 1 - type ok
ok 2 - final called: id = hello
ok 3 - this node is final
ok 4 - parent node is scxml
ok 5 - log called: expr = 'hello world'
ok 6 - this node is log
ok 7 - parent node is onentry
```

## Documentation-->
### Changes
One can find the changes document [here]()

## Installing

Use zef to install the package: `zef install XML::Actions`

## Versions of PERL, MOARVM

This project is tested against the newest perl6 version with Rakudo built on MoarVM implementing Perl v6.*.

## AUTHORS

Current maintainer **Marcel Timmerman** (MARTIMM on github)

## License

**Artistic-2.0**
