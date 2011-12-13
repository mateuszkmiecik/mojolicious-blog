#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Lite; # 'app', 'post', 'get', 'app' is exported
use Mojo::ByteStream 'b';
use utf8;

# Data file (app is Mojolicious object. home is Mojo::Home object)
my $data_file = app->home->rel_file('data.txt');

# Create entry
post '/create' => sub {
    my $self = shift; # ($self is Mojolicious::Controller object)
    
    # Form data(This data is Already decoded)
    my $title   = $self->param('title');
    my $message = $self->param('message');

    my $tit = $title;
    $tit = ''
      unless $title;
    
    my $mes = $message;
    $mes = ''
      unless $message;

    # Display error page if title is not exist.
    return $self->render(template => 'error', message  => 'Please input title', tiitle => $tit, mesag => $mes )
      unless $title;
    
    # Display error page if message is not exist.
    return $self->render(template => 'error', message => 'Please input content', tiitle => $tit, mesag => $mes )
      unless $message;
    
    # Check title length
    #return $self->render(template => 'error', message => 'Title is too long')
     # if length $title > 30;
    
    # Check message length
    #return $self->render(template => 'error', message => 'Message is too long')
     # if length $message > 100;
    
    # Data and time
    my ($sec, $min, $hour, $day, $month, $year) = localtime;
    $month = $month + 1; 
    $year = $year + 1900;
    
    # Format date (dd.mm.yyyy)
    my $datetime = sprintf("%02s.%02s.%04s", 
                           $day, $month, $year);
    
    # Line brakes to spaces
    $message =~ tr{\n}{ };
    
    # Writing data
    my $record = join("\t", $datetime, $title, $message) . "\n";
    
    # File open to write
    open my $data_fh, ">>", $data_file
      or die "Cannot open $data_file: $!";
    
    # Encode
    $record = b($record)->encode('UTF-8')->to_string;
    
    # Write
    print $data_fh $record;
    
    # Close
    close $data_fh;
    
    # Redirect
    $self->redirect_to('index');
    
} => 'create';

get '/style.css' => 'style';

get '/add' => 'add';

get '/' => sub {
    my $self = shift;
    
    # Open data file(Create file if not exist)
    my $mode = -f $data_file ? '<' : '+>';
    open my $data_fh, $mode, $data_file
      or die "Cannot open $data_file: $!";

    my $size = 0;

    # Read data
    my $entry_infos = [];
    while (my $line = <$data_fh>){
        chomp $line;
        my @record = split /\t/, $line;
        
        my $entry_info = {};
        $entry_info->{datetime} = $record[0];
        $entry_info->{title}    = $record[1];
        $entry_info->{message}  = $record[2];
        
        push @$entry_infos, $entry_info;

        $size = $size + 1;
    }
    
    # Close
    close $data_fh;
    
    # Reverse data order
    @$entry_infos = reverse @$entry_infos;

    if($size eq 0){
      $self->render('noposts');
    }else{
      $self->render(entry_infos => $entry_infos, size => $size);
    }
    
    # Render index page
} => 'index';

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Simple blog engine';
<% my $lol;
foreach my $entry_info (@$entry_infos) { %>
  <div class="blog-entry">
    <h3><%= $entry_info->{title} %> <span class="date"><%= $entry_info->{datetime} %> </span></h3>
    <p><%= $entry_info->{message} %></p>
  </div>
<% } %>

  <p class="number"><%= $size %> entries so far.</p>


@@ add.html.ep
% layout 'default';
% title 'Add post';
  <form method="post" action="<%= url_for('create') %>">
    <div>
      <label for="title">Title</label>
      <input type="text" name="title" value="" />
    </div>
    <div>
      <textarea name="message" cols="50" rows="10" ></textarea>
    </div>
    <div>
      <button type="submit" class="cupid-green">Post</button>
    </div>
    <hr />
  </form>


@@ noposts.html.ep
% layout 'default';
% title 'Simple blog engine';
<p>No entries.</p>

@@ error.html.ep
% layout 'default';
% title 'Add post';
<div class="error">
  <%= $message %>
</div>
  <form method="post" action="<%= url_for('create') %>">
    <div>
      <label for="title">Title</label>
      <input type="text" name="title" value="<%= $tiitle %>" />
    </div>
    <div>
      <textarea name="message" cols="50" rows="10" ><%= $mesag %></textarea>
    </div>
    <div>
      <button type="submit" class="cupid-green">Post</button>
    </div>
    <hr />
  </form>

@@ style.css.ep
* {
  border: 0;
  margin: 0;
  padding: 0;
}

body {
  background: #ccc;
  font: 14px/1.5 "Trebuchet MS", Tahoma, Verdana, Arial, sans-serif;
}

h3 {
  padding: 10px 20px;
  background: #fff;
}

div.blog-entry {
  border-bottom: 1px solid #ddd;
}

span.date  {
  float: right;
  font-style: italic;
  font-weight: normal;
  font-family: Georgia;
}

#container {
  width: 600px;
  margin: 20px auto;
  background-color: #F4F4F4;
  border-radius: 5px;
  -webkit-border-radius: 5px;
  -moz-border-radius: 5px;
  overflow: hidden;
  box-shadow: 0 1px #FFF inset, 0 -1px #DDD inset;
  -moz-box-shadow: 0 1px #FFF inset, 0 -1px #DDD inset;
  -webkit-box-shadow: 0 1px #FFF inset, 0 -1px #DDD inset;
}

#footer {
  width: 600px;
  margin: 0 auto;
  font-size: 10px;
  text-align: right;
  padding-bottom: 20px;
}

#footer a {
  margin-right: 20px;
}

h1, form {
  padding: 20px;
}

hr {
  border: 0;
  clear: both;
}

h1 {
  background: #ddd;
  box-shadow: inset 0 -1px 0 #bbb;
  -moz-box-shadow: inset 0 -1px 0 #bbb;
  -webkit-box-shadow: inset 0 -1px 0 #bbb;
}

form {
  box-shadow: inset 0 1px 0 #fff;
  -moz-box-shadow: inset 0 1px 0 #fff;
  -webkit-box-shadow: inset 0 1px 0 #fff;
}

input {
  border: 1px solid #aaa;
  border-radius: 3px;
  display: block;
  height: 30px;
  width: 540px;
  margin-bottom: 20px;
  padding: 5px 10px;
  font: 14px "Trebuchet MS", Tahoma, Verdana, Arial, sans-serif;
}

textarea {
  display: block;
  width: 540px;
  padding: 10px;
  border: 1px solid #aaa;
  border-radius: 3px;
  margin-bottom: 20px;
  font: 14px/1.5 "Trebuchet MS", Tahoma, Verdana, Arial, sans-serif;
}

label {
  float: left;
  display: none;
  margin-right: 30px;
  line-height: 40px;
}

form div {
  clear: both;
}

div.error {
  padding: 10px 20px;
  background: #FC81A0;
  border: 1px solid #FAAFC2;
  border-width: 1px 0;
  border-bottom-color: #E35D7E;
  color: #fff;
}

p {
  padding: 20px;
}

p.number {
  font-size: 12px;
  background: #eee;
  padding: 10px 20px;
  text-align: right;
}

button.cupid-green {
  background-color: #7fbf4d;
  background-image: -webkit-gradient(linear, left top, left bottom, from(#7fbf4d), to(#63a62f));
  /* Saf4+, Chrome */
  background-image: -webkit-linear-gradient(top, #7fbf4d, #63a62f);
  background-image: -moz-linear-gradient(top, #7fbf4d, #63a62f);
  background-image: -ms-linear-gradient(top, #7fbf4d, #63a62f);
  background-image: -o-linear-gradient(top, #7fbf4d, #63a62f);
  background-image: linear-gradient(top, #7fbf4d, #63a62f);
  border: 1px solid #63a62f;
  border-bottom: 1px solid #5b992b;
  -webkit-border-radius: 3px;
  -moz-border-radius: 3px;
  -ms-border-radius: 3px;
  -o-border-radius: 3px;
  border-radius: 3px;
  -webkit-box-shadow: inset 0 1px 0 0 #96ca6d;
  -moz-box-shadow: inset 0 1px 0 0 #96ca6d;
  -ms-box-shadow: inset 0 1px 0 0 #96ca6d;
  -o-box-shadow: inset 0 1px 0 0 #96ca6d;
  box-shadow: inset 0 1px 0 0 #96ca6d;
  color: #fff;
  font: bold 14px "Lucida Grande", "Lucida Sans Unicode", "Lucida Sans", Geneva, Verdana, sans-serif;
  display: block;
  float: right;
  line-height: 20px;
  padding: 7px 0 8px 0;
  text-align: center;
  text-shadow: 0 -1px 0 #4c9021;
  width: 150px; }
  button.cupid-green:hover {
    background-color: #76b347;
    background-image: -webkit-gradient(linear, left top, left bottom, from(#76b347), to(#5e9e2e));
    /* Saf4+, Chrome */
    background-image: -webkit-linear-gradient(top, #76b347, #5e9e2e);
    background-image: -moz-linear-gradient(top, #76b347, #5e9e2e);
    background-image: -ms-linear-gradient(top, #76b347, #5e9e2e);
    background-image: -o-linear-gradient(top, #76b347, #5e9e2e);
    background-image: linear-gradient(top, #76b347, #5e9e2e);
    -webkit-box-shadow: inset 0 1px 0 0 #8dbf67;
    -moz-box-shadow: inset 0 1px 0 0 #8dbf67;
    -ms-box-shadow: inset 0 1px 0 0 #8dbf67;
    -o-box-shadow: inset 0 1px 0 0 #8dbf67;
    box-shadow: inset 0 1px 0 0 #8dbf67;
    cursor: pointer; }
  button.cupid-green:active {
    border: 1px solid #5b992b;
    border-bottom: 1px solid #538c27;
    -webkit-box-shadow: inset 0 0 8px 4px #548c29, 0 1px 0 0 #eeeeee;
    -moz-box-shadow: inset 0 0 8px 4px #548c29, 0 1px 0 0 #eeeeee;
    -ms-box-shadow: inset 0 0 8px 4px #548c29, 0 1px 0 0 #eeeeee;
    -o-box-shadow: inset 0 0 8px 4px #548c29, 0 1px 0 0 #eeeeee;
    box-shadow: inset 0 0 8px 4px #548c29, 0 1px 0 0 #eeeeee; }


@@ layouts/default.html.ep
<!DOCTYPE html>
  <html>
    <head>
      <meta charset="utf-8" />
      <link href="/style.css" rel="stylesheet" />
      <title><%= title %></title>
    </head>
    <body>
      <div id="container">
        <h1><%= title %></h1>
        <%= content %>
      </div>
      <div id="footer">
        <a href="<%= url_for('add') %>">Add post.</a>
      </div>
    </body>
  </html>