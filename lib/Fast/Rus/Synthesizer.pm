use strict;
use warnings;

use v5.38;
use feature 'class';

no warnings 'experimental';

class Fast::Rus::Synthesizer {

  use Carp qw(croak);
  use Mojo::UserAgent;
  use Mojo::URL;
  use Mojo::Util   qw(url_escape);
  use Mojo::JSON   qw(decode_json);
  use MIME::Base64 qw(decode_base64);
  use IPC::Open2;

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

  field $text  //= 'Привет, мир!';
  field $speed //= 1;

  method text ($new_text) {
    $text = $new_text;
    return $self;
  }

  method synthesize () {
    my $enc_text = url_escape($text =~ s/(.)/sprintf '%%%02X', ord $1/gre, '%');
    my $syn_url  = $url . "&ttsp=tl:ru,txt:$enc_text,spd:2";
    my $tx       = $ua->get($syn_url);

    croak("Connection error: " . $tx->result->message) if !$tx->result->is_success;
    my $audio_data = decode_base64(decode_json(substr $tx->result->text, 5)->{translate_tts}[0]);

    return $self->adjust_audio_tempo($audio_data) if $speed != 1;
    return $audio_data;
  }

  method speed ($percent) {
    croak "Synth error: regulate tempo in range [50%, 300%]" if $percent < 50 or $percent > 300;

    $speed = $percent / 100;
    return $self;
  }

  method reset_speed () {
    $speed = 1;
    return $self;
  }

  method adjust_audio_tempo ($audio_data) {
    open2 my $out, my $in, "exec ffmpeg -i - -af 'atempo=$speed' -f mp3 - 2>/dev/null" or croak "Open2 error: $!";

    print $in $audio_data;
    close $in;

    local $/;
    $audio_data = <$out>;
    close $out;

    return $audio_data;
  }
}
