use strict;
use warnings;

use feature 'class';
use v5.38;

use Carp;
use Mojo::UserAgent;

class Synthesizer {
   my $ua = Mojo::UserAgent->new;
   my $url = Mojo::URL->scheme('https')
   ->host('www.google.com')
   ->path('async/translatte_tts')
   ->query(ei => 'emXtZ4rGMaymhbIPsY3nmQ8')
   ->query(opi => 89978449)
   ->query(sca_esv => 'c4fe9279b750d491')
   ->query(cs => 1)
   ->query(async => '_fmt:jspb')
   ->query(yv => 3);

   field $speed = 1;
   field $text  = 'Hello World!';

   method synthesize () {
      my $enc_text = 
      my $syn_url  = $url->query(tts => "txt:$enc_text,spd:$speed");
      my $tx = $ua->get("$syn_url");

      croak "Connection error: " . $tx->message if $tx->is_error;

   }

}
