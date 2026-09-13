#!/usr/bin/env perl6

use v6;
use lib '.', 'xt', 'lib', 'xt/lib';

use StoreBenchMarks;

sub MAIN (
  Str $bench-module = 'x', Int :$count = 100, Int :$tnbr = -1,
  Bool :$plot = False, Bool :$test = False,
) {

  if $test and $bench-module ne 'x' {
    try {

      require ::($bench-module);
      my $bm = ::($bench-module).new;

      note "prepare ...";
      $bm.?prepare-test();

      my StoreBenchMarks $sbm .= new;

      # Do 100 different tests in a module or specificaly $tnbr only
      my @n = $tnbr == -1 ?? ^100 !! ($tnbr,);
      for @n -> $test-count {

        # check if there is a test left
        last unless $bm.^can("run-test$test-count");
        note "Test 'run-test$test-count\()' ...";

        # get some data from test-data#()
        my Hash $data = $bm.?"test-data$test-count"() // {};
        $data<test> = $sbm.run-bench( $bm, "run-test$test-count", $count);
        $sbm.store-bench($data);
      }

      note "cleanup ...";
      $bm.?cleanup-test();

      CATCH {
        default {
          .say;
        }
      }
    }
  }

  if $plot {
    note "plot ...";
    my StoreBenchMarks $sbm .= new;
    $sbm.generate-plot();
  }
}
