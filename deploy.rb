#!/usr/bin/env ruby

%r(git checkout gh-pages)
%r(cp -rf ./_site/posts/* .)
%r(rm -rf ./_site/posts)
%r(git add -A)
%r(git commit -m "Deploy: #{Time.now.to_s}")
%r(git push origin gh-pages)
