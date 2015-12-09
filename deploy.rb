#!/usr/bin/env ruby

%x(jekyll)
%x(git checkout gh-pages)
%x(cp -rf ./_site/* .)
%x(cp -rf ./_site/posts/* .)
%x(rm -rf ./_site/posts)
%x(rm -rf ./posts)
%x(git add -A)
%x(git commit -m "Deploy: #{Time.now.to_s}")
%x(git push origin gh-pages)
