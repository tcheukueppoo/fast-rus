use strict;
use warnings;

use v5.38;
use feature 'class';

no warnings 'experimental';

class Fast::Rus::Synthesizer {

  use Carp qw(croak);
  use Mojo::UserAgent;
  use Mojo::URL;
  use Mojo::Util qw(url_escape);
  use Mojo::JSON qw(decode_json);
  use Encode;

  my $ua  = Mojo::UserAgent->new;
  my $url = Mojo::URL->new->scheme('https')
    ->host('www.google.com')
    ->path('async/translate_tts')
    ->query(
            ei      => 'emXtZ4rGMaymhbIPsY3nmQ8',
            opi     => 89978449,
            sca_esv => 'c4fe9279b750d491',
            cs      => 1,
            async   => '_fmt:jspb',
            yv      => 3,
           );

  field $speed = 2;
  field $text //= 'Привет, мир!';

  method text ($new_text) {
    $text = $new_text;
    return $self;
  }

  method synthesize () {
    my $enc_text = url_escape($text =~ s/(.)/sprintf '%%%02X', ord $1/gre, '%');
    my $syn_url  = $url . "&ttsp=tl:ru,txt:$enc_text,spd:$speed";
    my $tx       = $ua->get($syn_url);

    croak("Connection error: " . $tx->result->message) if !$tx->result->is_success;
    say decode_json(substr $tx->result->text, 5)->{'translate_tts'}[0];
  }

  method speedup () {
    $speed = 1.23;
    $self->synthesize();
  }

  method slowdown () {
    $speed-- if $speed > 1;
    $self->synthesize();
  }

  method reset_speed () {
    $speed = 1;
    return $self;
  }
}
