use v6;


class Y {
  method  y ( Int $y ) {
    note $y;
  }
}

my Y $y .= new;

sub b ( Int $i --> Int ) {
  note "$i"; $i + 10;
}


say 'run b(10)';
say b(10);

say 'run $y.?y(b(10))';
say $y.?y(b(10));

say 'run $y.?undef(b(10))';
say $y.?undef(b(10));
