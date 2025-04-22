use strict;
use warnings;
use v5.38;

use List::Util qw(uniq);

local $/;
my $js_code = <<>>;

my @coded_names = uniq($js_code =~ /.*?(_0x[0-9a-f]{,6})/g);
my @funny_names = qw(
  makeItSo
  doTheThing
  fluffyUnicornDance
  calculateTheAnswerToLife
  sendHelp
  panicButton
  fuzzyLogic
  makeItRain
  discoParty
  infiniteLoopOfDoom
  confettiExplosion
  robotUprising
  chickenNinjaAttack
  crazyIvan
  timeTraveler
  coffeeMachine
  procrastinationStation
  randomActOfKindness
  ninjaTraining
  superSecretFunction
  tacoTuesday
  bubbleSortOfLife
  theAnswerIs42
  warpSpeed
  sonicBoom
  magicHappens
  spaghettiCode
  debuggingHell
  functionThatDoesNothing
  theUltimateQuestion
  fartInSpace
  zombieApocalypse
);

my %map;

die "Update the funny name database!" if @coded_names > @funny_names;

$map{$coded_names[$_]} = $funny_names[$_] foreach 0 .. $#coded_names;

say $js_code =~ s/(_0x[0-9a-f]{,6})/$map{$1}/gre;
