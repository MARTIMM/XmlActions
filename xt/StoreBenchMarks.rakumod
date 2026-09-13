use v6;

use Telemetry;
use JSON::Fast;

#-------------------------------------------------------------------------------
unit class StoreBenchMarks;

has Str $bench-data-config;
has %!bench-data;

#-------------------------------------------------------------------------------
submethod BUILD ( ) {

  # load the coverage admin data.
  $!bench-data-config = "$*HOME/.config/bench-data.json";
  %!bench-data = %();
  %!bench-data = from-json($bench-data-config.IO.slurp // '')
    if $!bench-data-config.IO.r;
}

#-------------------------------------------------------------------------------
method run-bench ( $class-object, Str $method-name, Int $count --> Array ) {

  my Telemetry $t0 = Telemetry.new;
  for ^$count {
    $class-object."$method-name"();
  }

  [ Telemetry.new - $t0, $count]
}

#-------------------------------------------------------------------------------
method store-bench ( Hash $data ) {

  my Array $benched = $data<test> // [,];
  my Str $class-name = $data<class-name> // '*';
  my Str $sub-name = $data<sub-name> // '*';
  my Str $version = $data<version> // '*';
  my Str $note = $data<note> // '-';

  my Str $zulu-date = DateTime.now.utc.Str;
  my Str $p6-version = 'rakudo-' ~ $*PERL.compiler.version;
  my Str $test-name = [~] $class-name, '-', $sub-name,
                      '-', $*PROGRAM-NAME.IO.basename;

  my Telemetry $t = $benched[0];
  my Int $count = $benched[1];
#note $t.perl;

  %!bench-data{$test-name}{$zulu-date} = %( :$p6-version,
    :cpu($t<cpu>), :cpu-sys($t<cpu-sys>), :cpu-user($t<cpu-user>), :cpus($t<cpus>), :util($t<util%>), :max-rss($t<max-rss>), :wallclock($t<wallclock>), :nsig($t<nsig>),
    :$count, :$class-name, :$sub-name, :$version, :$note
  );

  $!bench-data-config.IO.spurt(to-json(%!bench-data));
}

#-------------------------------------------------------------------------------
method generate-plot ( ) {

  my Str $plot-filename = 'store-bench-marks';
  "$plot-filename.txt".IO.spurt('');

  for %!bench-data.keys -> $data-key {
    for %!bench-data{$data-key}.keys.sort -> $test-date {
      my %test-data = %!bench-data{$data-key}{$test-date};
      my $mean = ( %test-data<wallclock> / %test-data<count> ) / 1e6;
      my $mean-sys = ( %test-data<cpu-sys> / %test-data<count> ) / 1e6;
      my $mean-usr = ( %test-data<cpu-user> / %test-data<count> ) / 1e6;
      "$plot-filename.txt".IO.spurt(
        "%test-data<p6-version>, $data-key, $mean, $mean-sys, $mean-usr, %test-data<count>, {%test-data<count> / (%test-data<wallclock> / 1e6)}, \n",
        :append
      );
    }
  }

# uninstalled, didn't work  run 'perl6', '/opt/Perl6/rakudo/install/share/perl6/site/bin/graph-bench.pl', "$plot-filename.txt";
}
