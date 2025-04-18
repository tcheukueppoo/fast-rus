use strict;
use warnings;

use v5.38;
use feature 'class';

no warnings 'experimental';

class Fast::Rus::AI {
  use Mojo::UserAgent;
  use Carp qw(croak);

  my $headers = {
      "User-Agent" =>
      "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
      "Accept"          => "text/event-stream",
      "Accept-Language" => "de,en-US;q=0.7,en;q=0.3",
      "Accept-Encoding" => "gzip, deflate, br",
      "Referer"         => "https://duckduckgo.com/?q=DuckDuckGo+AI+Chat&ia=chat&duckai=1",
      "Content-Type"    => "application/json",
      "Origin"          => "https://duckduckgo.com",
      "Connection"      => "keep-alive",
      "Cookie"          => "dcm=1; bg=-1",
      "Sec-Fetch-Dest"  => "empty",
      "Sec-Fetch-Mode"  => "cors",
      "Sec-Fetch-Site"  => "same-origin",
      "Pragma"          => "no-cache",
      "TE"              => "trailers",
      "x-vqd-accept"    => "1",
      "cache-control"   => "no-store"

                };

  my $status_url = 'https://duckduckgo.com/duckchat/v1/status';
  my $chat_url   = 'https://duckduckgo.com/duckchat/v1/chat';

  my %models = (
    'gpt-4o' => 'gpt-4o-mini',
    'claude-3' => 'claude-3-haiku-20240307',
    'llama' => 'meta-llama/Llama-3.3-70B-Instruct-Turbo',
    'o3' => 'o3-mini',
    'mistral' => 'mistralai/Mistral-Small-24B-Instruct-2501'
  );

  my $ua = Mojo::UserAgent->new;

  field $conv_id;
  field $model //= 'gpt-4o';
  field @messages;

  method ADJUST {
     # Create a new conversation id for each instance.
     _set_new_conv_id
  }

  method _set_new_conv_id () {
     my $tx = $ua->get($status_url => {%headers});

     croak "Connection error: " . $tx->result->message  unless $tx->result->is_success;
     $conv_id = $tx->result->headers->header('x-vqd-4');
  }

  method model ($new_model) {
     croak "Unknown model '$new_model'" unless exists $models{$new_model};

     $model = $models{$new_model};
     _set_new_conv_id;
  }

  method chat ($question) {
      push @messages, { content => $question, role => 'user' };

      croak "Unexpected error: 'conv_id' is undefined" unless defined $conv_id;
      my $tx = $ua->post($chat_url => {%headers, 'x-vqd-4' => $conv_id } => json => {model => $model, messages => @messages});

      croak "Connection error: " . $tx->result->message, pop @messages unless $tx->result->is_success;

      # Save the new conversation id
      $conv_id = $tx->result->headers->header('x-vqd-4');

      # Stream the response

  }
}
