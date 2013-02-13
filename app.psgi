#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Web::Scraper;
use Config::Pit;
use WWW::Mechanize;

my @urls = urls();

my $app = sub {
    my $env  = shift;
    my $html = sprintf(<<HTML, $urls[int(rand(@urls))]);
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="refresh" content="0;url=%s">
  </head>
</html>
HTML
    return [
        200,
        [ 'Content-Type' => 'text/html' ],
        [ $html ],
    ];
};

sub config {
    pit_get("www.pixiv.net", require => {
        "pixiv_id" => "your pixiv_id",
        "pass"     => "your pass",
    });
}

sub urls {
    my $mech = WWW::Mechanize->new();
    $mech->get("https://www.secure.pixiv.net/login.php");
    $mech->submit_form(
        form_number => 2,
        fields      => config(),
    );
    $mech->get("http://www.pixiv.net/ranking.php?mode=daily&content=illust");
    my $scraper = scraper {
        process "article > a", "url[]" => '@href';
    };
    my $res = $scraper->scrape($mech->content());
    map { "http://www.pixiv.net/$_" } @{$res->{url}};
}
