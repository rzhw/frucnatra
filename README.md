# Frucnatra

Frucnatra is a port/implementation of Sinatra which runs on PHP, thanks to
[Fructose](https://github.com/charliesome/Fructose). And of course, it's a
lot like Sinatra:

    # index.rb
    require 'frucnatra'
    
    get '/' do
      'Hello world!'
    end

Put this in your <tt>.htaccess</tt>:

    Options +FollowSymlinks

    RewriteEngine On

    RewriteCond %{REQUEST_FILENAME} !index\.php

    RewriteRule ^(.*)$ index.php/$1 [NC]

Make sure you have .NET 4.0 installed, and have `Microsoft.Dynamic.dll`
and `Microsoft.Scripting.dll` in the `compiler` directory:

    compiler\Fructose.exe index.rb

## Differences

No docs on this yet.

## Implemented

Basic routes, redirect, status