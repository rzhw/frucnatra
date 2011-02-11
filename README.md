# Frucnatra

Put this in your <del>pipe</del> cinnamon

    require :frucnatra
    get '/hi' do
      "Hello World!"
    end

And <del>smoke it</del> put it in an apple pie or something

    Options +FollowSymlinks
    RewriteEngine On
    RewriteRule ^(.*)$ frucnatra.php/$1 [NC]

## What's supported

Nothing except for routes