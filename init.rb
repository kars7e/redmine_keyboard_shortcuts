require_dependency 'issues_controller_patch'

Redmine::Plugin.register :redmine_keyboard_shortcuts do
  name 'Redmine Keyboard Shortcuts'
  author 'Austin Smith (modified by Karol Stepniewski)'
  description 'Add keyboard shortcuts to Redmine'
  version '0.0.2'
  url 'https://github.com/kars7e/redmine_keyboard_shortcuts'
  author_url 'http://blog.bigfun.eu'
end

require 'redmine_keyboard_shortcuts/hooks.rb'