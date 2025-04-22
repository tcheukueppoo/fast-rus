use v5.38;
use feature 'class';

no warnings 'experimental';

class Fast::Rus::DuckAI;

use strict;

use Carp            qw(croak);
use Storable        qw(store retrieve);
use Fast::Rus::Util qw(gen_user_agent duckai_common_req_headers);
use Mojo::UserAgent;
use Data::Dumper qw(Dumper);

my $ua = Mojo::UserAgent->new;

my $status_url = 'https://duckduckgo.com/duckchat/v1/status';
my %status_headers = (
                      'Accept'        => '*/*',
                      #'x-vqd-accept'  => 1,
                      'Cache-Control' => 'no-store',
                     );

my $chat_url = 'https://duckduckgo.com/duckchat/v1/chat';
my %chat_headers = (
                    'Accept'       => 'text/event-stream',
                    'Content-Type' => 'application/json',
                    'Origin'       => 'https://duckduckgo.com',
                    'Priority'     => 'u=4',
                   );
my %models = (
              'gpt-4o'   => 'gpt-4o-mini',
              'claude-3' => 'claude-3-haiku-20240307',
              'llama'    => 'meta-llama/Llama-3.3-70B-Instruct-Turbo',
              'o3'       => 'o3-mini',
              'mistral'  => 'mistralai/Mistral-Small-24B-Instruct-2501'
             );

my $max_req = 20;

field $conv;
field $conv_file : param //= undef;
field $model : param     //= 'gpt-4o';

ADJUST {
  if (defined $conv_file && -f $conv_file && -r _) {
    $conv = retrieve($conv_file);

    croak "Inconsistent data found in '$conv_file'"
      unless exists $conv->{id}
      && exists $conv->{messages}
      && exists $conv->{n_req}
      && exists $conv->{ua_header}
      && exists $conv->{model}
      && exists $models{$conv->{model}};

    $self->_new_conv() if $conv->{n_req} >= $max_req;
  }
  else {
    $self->_new_conv();
  }
}

method _new_conv () {
  my $ua_header = gen_user_agent();
  my $tx = $ua->get(
                    $status_url => {
                                    %status_headers, duckai_common_req_headers(), 'User-Agent' => $ua_header,
                    'Priority'     => 'u=0',

                      'x-vqd-accept'  => 1,
                                   }
                   );

  croak 'Connection error: ' . $tx->result->message unless $tx->result->is_success;

  $conv->{messages}  = undef;
  $conv->{n_req}     = 0;
  $conv->{id}        = $tx->result->headers->header('x-vqd-4');
  $conv->{ua_header} = $ua_header;
  $conv->{model}     = $models{$model};
}

method save_conv ($path) {
  store($conv, $path);
}

method model ($new_model) {
  croak "Unknown model '$new_model'" unless exists $models{$new_model};

  $conv->{model} = $new_model;
  $self->_new_conv();

  return $self;
}

method chat ($content) {
  $self->_new_conv if $conv->{n_req} >= $max_req;

  foreach (1..2) {
     sleep 1;
   say $ua->get($status_url, {duckai_common_req_headers(), %status_headers, 'User-Agent' => $conv->{ua_header}, 'Priority' => 'u=4',})->result->body;
   }

  push $conv->{messages}->@*,
    {
     content => $content,
     role    => 'user',
    };

  croak 'Unexpected error: conv id undefined' unless defined $conv->{id};
  my $tx = $ua->post(
                     $chat_url => {
                                   %chat_headers, duckai_common_req_headers,
                                   'X-Vqd-4'    => $conv->{id},
                                   'User-Agent' => $conv->{ua_header},
                                  },
                     json => {
                              model    => $conv->{model},
                              messages => $conv->{messages},
                             }
                    );

  croak('Connection error: ' . Dumper ($tx->req->headers ). "code: " . $tx->res->code), pop $conv->{messages}->@* unless $tx->result->is_success;

  # Save the new conversation id
  $conv->{id} = $tx->result->headers->header('x-vqd-4');
  $conv->{n_req}++;

  # Stream the response
  return $tx->result->body;
}
