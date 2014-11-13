
# allow all Identity subclasses to be defined in a single file
require_dependency File.join "app","models","identity.rb" if Rails.env.development?
